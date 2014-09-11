class StudentsSyncronizerWorker
  include Sidekiq::Worker

  def perform(syncronization_id)
    syncronization = IeducarApiSyncronization.find(syncronization_id)

    begin
      api = IeducarApi::Students.new(syncronization.to_api)

      students = api.fetch["alunos"]

      StudentsSyncronizer.syncronize!(students)

      syncronization.mark_as_completed!
    rescue IeducarApi::Base::ApiError => e
      syncronization.mark_as_error!(e.message)
    end
  end
end
