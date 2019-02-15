class IeducarSynchronizerWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, retry: false, dead: false

  def perform(entity_id = nil, synchronization_id = nil)
    if entity_id
      perform_for_entity(
        Entity.find(entity_id),
        synchronization_id
      )
    else
      all_entities.each do |entity|
        IeducarSynchronizerWorker.perform_async(
          entity.id,
          synchronization_id
        )
      end
    end
  end

  private

  BASIC_SYNCHRONIZERS = [
    KnowledgeAreasSynchronizer.to_s,
    DisciplinesSynchronizer.to_s,
    StudentsSynchronizer.to_s,
    DeficienciesSynchronizer.to_s,
    RoundingTablesSynchronizer.to_s,
    RecoveryExamRulesSynchronizer.to_s,
    CoursesGradesClassroomsSynchronizer.to_s,
    TeachersSynchronizer.to_s,
    StudentEnrollmentDependenceSynchronizer.to_s
  ].freeze

  def perform_for_entity(entity, synchronization_id)
    entity.using_connection do
      begin
        synchronization = IeducarApiSynchronization.find_by(id: synchronization_id)

        if synchronization.blank?
          configuration = IeducarApiConfiguration.current
          break unless configuration.persisted?

          synchronization = configuration.start_synchronization(User.first)
          if synchronization.present?
            synchronization.job_id = jid unless synchronization.job_id
          end
        end

        break unless synchronization.persisted? && synchronization.started?

        worker_batch = WorkerBatch.create!(
          main_job_class: IeducarSynchronizerWorker.to_s,
          main_job_id: synchronization.job_id
        )
        worker_batch.start!

        total = []

        BASIC_SYNCHRONIZERS.each do |klass|
          increment_total(total) do
            klass.constantize.synchronize!(
              synchronization,
              worker_batch,
              years_to_synchronize
            )
          end
        end

        total << SpecificStepClassroomsSynchronizer.synchronize!(
          entity.id,
          synchronization.id,
          worker_batch.id
        )

        years_to_synchronize.each do |year|
          increment_total(total) do
            ExamRulesSynchronizer.synchronize!(
              synchronization,
              worker_batch,
              [year]
            )
          end

          Unity.with_api_code.each do |unity|
            increment_total(total) do
              StudentEnrollmentSynchronizer.synchronize!(
                synchronization,
                worker_batch,
                [year],
                unity.api_code,
                entity.id
              )
            end
          end
        end

        increment_total(total) do
          StudentEnrollmentExemptedDisciplinesSynchronizer.synchronize!(
            synchronization,
            worker_batch
          )
        end

        worker_batch.with_lock do
          worker_batch.update(total_workers: total.sum)

          if worker_batch.all_workers_finished?
            worker_batch.end!
            synchronization.mark_as_completed!
          end
        end
      rescue StandardError => error
        synchronization.mark_as_error!('Erro desconhecido.', error.message) if error.class != Sidekiq::Shutdown

        raise error
      end
    end
  end

  def years_to_synchronize
    @years ||= Unity.with_api_code
                    .joins(:school_calendars)
                    .pluck('school_calendars.year')
                    .uniq
                    .reject(&:blank?).sort
  end

  def all_entities
    Entity.all
  end

  def increment_total(total, &block)
    total << 1

    block.yield
  end
end
