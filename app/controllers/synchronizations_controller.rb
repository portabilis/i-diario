class SynchronizationsController < ApplicationController
 def create
   configuration = IeducarApiConfiguration.current
   @synchronization = configuration.start_synchronization!(current_user)

   IeducarSynchronizerWorker.perform_async(current_entity.id, @synchronization.id)

   respond_with @synchronization, location: edit_ieducar_api_configurations_path
 end
end
