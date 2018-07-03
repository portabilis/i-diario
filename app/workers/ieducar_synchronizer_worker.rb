class IeducarSynchronizerWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, retry: 5

  def perform(entity_id = nil, synchronization_id = nil)
    if entity_id
      entity = Entity.find(entity_id)
      perform_for_entity(entity, synchronization_id)
    else
      all_entities.each do |entity|
        IeducarSynchronizerWorker.perform_async(entity.id, synchronization_id)
      end
    end
  end

  private

  def perform_for_entity(entity, synchronization_id)
    entity.using_connection do
      begin
        unless synchronization = IeducarApiSynchronization.find_by_id(synchronization_id)
          configuration = IeducarApiConfiguration.current
          break unless configuration.persisted?
          synchronization = configuration.start_synchronization!(User.first)
          synchronization.job_id = self.jid unless synchronization.job_id
        end

        worker_batch = WorkerBatch.create!(main_job_class: 'IeducarSynchronizerWorker', main_job_id: synchronization.job_id)

        total = []

        increment_total(total) do
          KnowledgeAreasSynchronizer.synchronize!(synchronization, worker_batch)
        end

        increment_total(total) do
          DisciplinesSynchronizer.synchronize!(synchronization, worker_batch)
        end

        increment_total(total) do
          StudentsSynchronizer.synchronize!(synchronization, worker_batch)
        end

        increment_total(total) do
          DeficienciesSynchronizer.synchronize!(synchronization, worker_batch)
        end

        increment_total(total) do
          ***REMOVED***sSynchronizer.synchronize!(synchronization, worker_batch)
        end

        increment_total(total) do
          RoundingTablesSynchronizer.synchronize!(synchronization, worker_batch)
        end

        increment_total(total) do
          RecoveryExamRulesSynchronizer.synchronize!(synchronization, worker_batch)
        end

        increment_total(total) do
          TeachersSynchronizer.synchronize!(synchronization, worker_batch, years_to_synchronize)
        end

        increment_total(total) do
          CoursesGradesClassroomsSynchronizer.synchronize!(synchronization, worker_batch)
        end

        increment_total(total) do
          StudentEnrollmentDependenceSynchronizer.synchronize!(synchronization, worker_batch, years_to_synchronize)
        end

        total << SpecificStepClassroomsSynchronizer.synchronize!(entity.id, synchronization.id, worker_batch.id)

        years_to_synchronize.each do |year|
          increment_total(total) do

            ExamRulesSynchronizer.synchronize!(synchronization, worker_batch, [year])
          end

          Unity.with_api_code.each do |unity|
            increment_total(total) do

              StudentEnrollmentSynchronizer.synchronize!(synchronization, worker_batch, [year], unity.api_code)
            end
          end
        end

        increment_total(total) do
          StudentEnrollmentExemptedDisciplinesSynchronizer.synchronize!(synchronization, worker_batch)
        end

        worker_batch.with_lock do
          worker_batch.update_attribute(:total_workers, total.sum)

          if worker_batch.all_workers_finished?
            synchronization.mark_as_completed!
          end
        end
      rescue Exception => e
        synchronization.mark_as_error!('Erro desconhecido.', e.message)
        raise e
      end
    end
  end

  def years_to_synchronize
    @years ||= Unity.with_api_code.map { |unity| CurrentSchoolYearFetcher.new(unity).fetch }.uniq.reject(&:blank?).sort
  end

  def all_entities
    Entity.all
  end

  def increment_total(total, &block)
    total << 1

    block.call
  end
end
