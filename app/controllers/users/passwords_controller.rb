class Users::PasswordsController < Devise::PasswordsController
  def update
    password = params[:user][:password]
    token = params[:user][:reset_password_token]
    if weak_password?(password)
      flash[:error] = I18n.t('errors.general.weak_password')
      redirect_to edit_user_password_path(reset_password_token: token)
    else
      super
    end
  end
end
