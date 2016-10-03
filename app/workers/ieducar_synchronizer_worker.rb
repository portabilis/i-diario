class IeducarSynchronizerWorker
  include Sidekiq::Worker

  def perform(entity_id, synchronization_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      synchronization = IeducarApiSynchronization.find(synchronization_id)

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
          StudentEnrollmentDependenceSynchronizer.synchronize!(synchronization, year)
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

  private

  def years_to_synchronize
    Unity.with_api_code.map { |unity| CurrentSchoolYearFetcher.new(unity).fetch }
      .uniq
      .reject(&:blank?)
      .sort
  end
end
