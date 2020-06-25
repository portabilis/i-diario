class SynchronizationsController < ApplicationController
  def create
    full_synchronization = params.fetch(:full, false)
    configuration = IeducarApiConfiguration.current
    @synchronization = configuration.start_synchronization(current_user, current_entity.id, full_synchronization)

    if @synchronization.persisted?
      respond_with @synchronization, location: edit_ieducar_api_configurations_path
    else
      flash_for_sync_error

      redirect_to edit_ieducar_api_configurations_path
    end

  rescue ActiveRecord::RecordNotUnique
    redirect_to edit_ieducar_api_configurations_path
  end

  def current_syncronization_data
    current_syncronization = IeducarApiSynchronization.find_by(status: ApiSynchronizationStatus::STARTED)

    render json: {
      time_running: current_syncronization&.time_running,
      done_percentage: current_syncronization&.done_percentage
    }
  end

  private

  def flash_for_sync_error
    if @synchronization.errors.messages[:ieducar_api_configuration_id].include?(I18n.t('errors.messages.taken'))
      flash[:notice] = I18n.t('flash.synchronizations.create.notice')
    else
      flash[:alert] = I18n.t('flash.synchronizations.create.alert')
    end
  end
end
