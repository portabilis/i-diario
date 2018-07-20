class SynchronizationsController < ApplicationController
  def create
    configuration = IeducarApiConfiguration.current
    @synchronization = configuration.start_synchronization!(current_user)

    job_id = IeducarSynchronizerWorker.perform_in(5.seconds, current_entity.id, @synchronization.id)

    @synchronization.set_job_id!(job_id)

    respond_with @synchronization, location: edit_ieducar_api_configurations_path
  end
end
