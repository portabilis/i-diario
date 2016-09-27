class IeducarSynchronizerWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1

  def perform(entity_id = nil, synchronization_id = nil)
    if entity_id
      entity = Entity.find(entity_id)
      perform_for_entity(entity, synchronization_id)
    else
      all_entities.each do |entity|
        perform_for_entity(entity, synchronization_id)
      end
    end
  end

  private

  def perform_for_entity(entity, synchronization_id)
    entity.using_connection do
      unless synchronization = IeducarApiSynchronization.find_by_id(synchronization_id)
        configuration = IeducarApiConfiguration.current
        synchronization = configuration.start_synchronization!(User.find_by_id(1))
      end

      begin
        KnowledgeAreasSynchronizer.synchronize!(synchronization)
        DisciplinesSynchronizer.synchronize!(synchronization)
        StudentsSynchronizer.synchronize!(synchronization)
        DeficienciesSynchronizer.synchronize!(synchronization)
        ***REMOVED***sSynchronizer.synchronize!(synchronization)
        RoundingTablesSynchronizer.synchronize!(synchronization)
        RecoveryExamRulesSynchronizer.synchronize!(synchronization)

        years_to_synchronize.each do |year|
          CoursesGradesClassroomsSynchronizer.synchronize!(synchronization, year)
          TeachersSynchronizer.synchronize!(synchronization, year)
          ExamRulesSynchronizer.synchronize!(synchronization, year)
          StudentEnrollmentSynchronizer.synchronize!(synchronization, year)
        end

        synchronization.mark_as_completed!
      rescue IeducarApi::Base::ApiError => e
        synchronization.mark_as_error!(e.message)
      rescue Exception => exception
        synchronization.mark_as_error!('Ocorreu um erro desconhecido.')

        raise exception
      end
    end
  end

  def years_to_synchronize
    Unity.with_api_code.map { |unity| CurrentSchoolYearFetcher.new(unity).fetch }
      .uniq
      .reject(&:blank?)
      .sort
  end

  def all_entities
    Entity.all
  end

end
