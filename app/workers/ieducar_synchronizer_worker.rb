class IeducarSynchronizerWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, retry: 3, dead: false

  sidekiq_retries_exhausted do |msg, exception|
    entity_id, synchronization_id = msg['args']

    Entity.find(entity_id).using_connection do
      synchronization = IeducarApiSynchronization.find(synchronization_id)
      synchronization.mark_as_error!(
        I18n.t('ieducar_api.error.messages.sync_error'),
        exception.message
      )
    end
  end

  def perform(entity_id = nil, synchronization_id = nil)
    if entity_id.present? && synchronization_id.present?
      perform_for_entity(
        Entity.find(entity_id),
        synchronization_id
      )
    else
      all_entities.each do |entity|
        entity.using_connection do
          configuration = IeducarApiConfiguration.current

          next unless configuration.persisted?

          configuration.start_synchronization(User.first, entity.id)
        end
      end
    end
  end

  private

  SYNCHRONIZERS = [
    DeficienciesSynchronizer.to_s,
    StudentsSynchronizer.to_s,
    KnowledgeAreasSynchronizer.to_s,
    DisciplinesSynchronizer.to_s,
    RoundingTablesSynchronizer.to_s,
    CoursesSynchronizer.to_s,
    GradesSynchronizer.to_s,
    ClassroomsSynchronizer.to_s,
    SpecificStepsSynchronizer.to_s,
    ExamRulesSynchronizer.to_s,
    RecoveryExamRulesSynchronizer.to_s,
    TeachersSynchronizer.to_s,
    TeacherDisciplineClassroomsSynchronizer.to_s,
    StudentEnrollmentSynchronizer.to_s,
    StudentEnrollmentClassroomSynchronizer.to_s,
    StudentEnrollmentDependenceSynchronizer.to_s,
    StudentEnrollmentExemptedDisciplinesSynchronizer.to_s
  ].freeze

  def perform_for_entity(entity, synchronization_id)
    entity.using_connection do
      begin
        synchronization = IeducarApiSynchronization.started.find_by(id: synchronization_id)

        break unless synchronization.try(:started?)

        worker_batch = synchronization.worker_batch
        worker_batch.start!
        worker_batch.update(total_workers: SYNCHRONIZERS.size)

        SYNCHRONIZERS.each do |klass|
          klass.constantize.synchronize_in_batch!(
            synchronization: synchronization,
            worker_batch: worker_batch,
            years: years_to_synchronize,
            entity_id: entity.id,
            unities_api_code: unities_api_code
          )
        end
      rescue Sidekiq::Shutdown => error
        raise error
      rescue StandardError => error
        if error.message != '502 Bad Gateway'
          synchronization.mark_as_error!(I18n.t('ieducar_api.error.messages.sync_error'), error.message)
        end

        raise error
      end
    end
  end

  def unities_api_code
    @unities_api_code ||= Unity.with_api_code.pluck(:api_code)
  end

  def years_to_synchronize
    # TODO voltar a sincronizar todos os anos uma vez por semana (Sábado)
    @years_to_synchronize ||= Unity.with_api_code
                                   .joins(:school_calendars)
                                   .pluck('school_calendars.year')
                                   .uniq
                                   .sort
                                   .compact
                                   .last(2)
  end

  def all_entities
    Entity.active
  end
end
