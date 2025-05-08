class AdminSynchronizationsController < ApplicationController
  def index
    @entity_syncs = AdminSynchronization.new
  end

  def cancel
    error = I18n.t('ieducar_api_synchronization.canceled')
    IeducarApiSynchronization.find(params[:ieducar_api_synchronization_id]).cancel!(false, current_entity.id, error)

    redirect_to :back
  end
end
