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
    { klass: DeficienciesSynchronizer.to_s, by_year: false, by_unity: false },
    { klass: StudentsSynchronizer.to_s, by_year: false, by_unity: false },
    { klass: KnowledgeAreasSynchronizer.to_s, by_year: false, by_unity: false },
    { klass: DisciplinesSynchronizer.to_s, by_year: false, by_unity: false },
    { klass: RoundingTablesSynchronizer.to_s, by_year: false, by_unity: false },
    { klass: CoursesSynchronizer.to_s, by_year: false, by_unity: true },
    { klass: GradesSynchronizer.to_s, by_year: false, by_unity: true },
    { klass: ClassroomsSynchronizer.to_s, by_year: true, by_unity: true },
    { klass: SpecificStepsSynchronizer.to_s, by_year: false, by_unity: false },
    { klass: ExamRulesSynchronizer.to_s, by_year: true, by_unity: false },
    { klass: RecoveryExamRulesSynchronizer.to_s, by_year: false, by_unity: false },
    { klass: TeachersSynchronizer.to_s, by_year: true, by_unity: false },
    { klass: TeacherDisciplineClassroomsSynchronizer.to_s, by_year: true, by_unity: false },
    { klass: StudentEnrollmentSynchronizer.to_s, by_year: true, by_unity: true },
    { klass: StudentEnrollmentClassroomSynchronizer.to_s, by_year: true, by_unity: true },
    { klass: StudentEnrollmentDependenceSynchronizer.to_s, by_year: true, by_unity: false },
    { klass: StudentEnrollmentExemptedDisciplinesSynchronizer.to_s, by_year: false, by_unity: false }
  ].freeze

  def perform_for_entity(entity, synchronization_id)
    entity.using_connection do
      begin
        synchronization = IeducarApiSynchronization.started.find_by(id: synchronization_id)

        break unless synchronization.try(:started?)

        worker_batch = synchronization.worker_batch
        worker_batch.start!
        worker_batch.update(total_workers: total_synchronizers(synchronization.full_synchronization))

        SYNCHRONIZERS.each do |synchronizer|
          synchronizer[:klass].constantize.synchronize_in_batch!(
            synchronization: synchronization,
            worker_batch: worker_batch,
            entity_id: entity.id,
            years: years_to_synchronize,
            unities_api_code: unities_api_code,
            filtered_by_year: synchronizer[:by_year],
            filtered_by_unity: synchronizer[:by_unity]
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
    @years_to_synchronize ||= Unity.with_api_code
                                   .joins(:school_calendars)
                                   .pluck('school_calendars.year')
                                   .uniq
                                   .sort
                                   .compact
  end

  def all_entities
    Entity.active
  end

  def total_synchronizers(full_synchronization)
    return total_synchronizers_with_full_synchronization if full_synchronization

    total_synchronizers_with_simple_synchronization
  end

  def total_synchronizers_with_full_synchronization
    (
      (synchronizers_by_year_and_unity.size * years_to_synchronize.size * unities_api_code.size) +
      (synchronizers_by_year.size * years_to_synchronize.size) +
      (synchronizers_by_unity.size * unities_api_code.size) +
      single_synchronizers.size
    )
  end

  def total_synchronizers_with_simple_synchronization
    (
      (synchronizers_by_year_and_unity.size * years_to_synchronize.size) +
      (synchronizers_by_year.size * years_to_synchronize.size) +
      synchronizers_by_unity.size +
      single_synchronizers.size
    )
  end

  def single_synchronizers
    @single_synchronizers ||= SYNCHRONIZERS.select { |synchronizer|
      !synchronizer[:by_year] && !synchronizer[:by_unity]
    }
  end

  def synchronizers_by_year
    @synchronizers_by_year ||= SYNCHRONIZERS.select { |synchronizer|
      synchronizer[:by_year] && !synchronizer[:by_unity]
    }
  end

  def synchronizers_by_unity
    @synchronizers_by_unity ||= SYNCHRONIZERS.select { |synchronizer|
      !synchronizer[:by_year] && synchronizer[:by_unity]
    }
  end

  def synchronizers_by_year_and_unity
    @synchronizers_by_year_and_unity ||= SYNCHRONIZERS.select { |synchronizer|
      synchronizer[:by_year] && synchronizer[:by_unity]
    }
  end
end
