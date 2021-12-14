class Users::UnlocksController < Devise::UnlocksController
  def create
    self.resource = resource_class.send_unlock_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_unlock_instructions_path_for(resource))
    else
      if resource.errors.any?
        set_errors(resource.errors.messages)
      end

      redirect_to new_user_unlock_path
    end
  end

  def show
    super
    self.resource.update_columns(status: "active") if self.resource.persisted?
  end

  private

  def set_errors(error)
    not_bloqued = error[:email].first == "não estava bloqueado"
    not_found = error[:email].first == "não encontrado"

    return flash[:error] = I18n.t('devise.unlocks.not_bloqued') if not_bloqued
    return flash[:error] = I18n.t('devise.unlocks.user_not_found') if not_found

    flash[:error] = I18n.t('devise.unlocks.unsent_instructions')
  end
end
