class IeducarSynchronizerWorker
  include Sidekiq::Worker

  def perform(synchronization_id)
    synchronization = IeducarApiSyncronization.find(synchronization_id)

    begin
      # synchronize Students
      StudentsSynchronizer.synchronize!(synchronization)

      # synchronize Deficiencies
      DeficienciesSynchronizer.synchronize!(synchronization)

      synchronization.mark_as_completed!
    rescue IeducarApi::Base::ApiError => e
      synchronization.mark_as_error!(e.message)
    end
  end
end
