class IeducarSynchronizerWorker
  include Sidekiq::Worker

  def perform(entity_id, synchronization_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      synchronization = IeducarApiSyncronization.find(synchronization_id)

      begin
        # synchronize Students
        StudentsSynchronizer.synchronize!(synchronization)

        # synchronize Deficiencies
        DeficienciesSynchronizer.synchronize!(synchronization)

        # synchronize Unities
        UnitiesSynchronizer.synchronize!(synchronization)

        synchronization.mark_as_completed!
      rescue IeducarApi::Base::ApiError => e
        synchronization.mark_as_error!(e.message)
      end
    end
  end
end
