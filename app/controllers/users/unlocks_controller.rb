class Users::UnlocksController < Devise::UnlocksController
  def create
    self.resource = resource_class.send_unlock_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_unlock_instructions_path_for(resource))
    else
      flash[:error] = I18n.t('devise.unlocks.not_send_instructions')
      redirect_to new_user_unlock_path
    end
  end
  def show
    super
    self.resource.update_columns(status: "active") if self.resource.persisted?
  end
end
