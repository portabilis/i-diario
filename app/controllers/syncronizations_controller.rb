class SyncronizationsController < ApplicationController
  def create
    configuration = IeducarApiConfiguration.current
    @syncronization = configuration.start_syncronization!(current_user)

    StudentsSyncronizerWorker.perform_async(@syncronization.id)

    respond_with @syncronization, location: edit_ieducar_api_configurations_path
  end
end
