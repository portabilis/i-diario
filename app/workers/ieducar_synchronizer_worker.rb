class IeducarSynchronizerWorker
  include Sidekiq::Worker

  def perform(entity_id, synchronization_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      synchronization = IeducarApiSyncronization.find(synchronization_id)

      begin
        # synchronize Classrooms
        ClassroomsSynchronizer.synchronize!(synchronization)

        # synchronize Disciplines
        DisciplinesSynchronizer.synchronize!(synchronization)

        # synchronize Students
        StudentsSynchronizer.synchronize!(synchronization)

        # synchronize Deficiencies
        DeficienciesSynchronizer.synchronize!(synchronization)

        # synchronize Disciplinary Occurrences
        ***REMOVED***sSynchronizer.synchronize!(synchronization)

        synchronization.mark_as_completed!
      rescue IeducarApi::Base::ApiError => e
        synchronization.mark_as_error!(e.message)
      end
    end
  end
end
