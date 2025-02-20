class AdminSynchronizationsController < ApplicationController
  def index
  end

  def cancel
    error = I18n.t('ieducar_api_synchronization.canceled')
    IeducarApiSynchronization.find(params[:ieducar_api_synchronization_id]).cancel!(false, error)

    redirect_to :back
  end
end
