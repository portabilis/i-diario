class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :passport

  def passport
    email = request.env['omniauth.auth']&.dig('info', 'email')
    @user = User.find_by(email: email)

    if @user&.active_for_authentication?
      set_flash_message(:notice, :success, kind: 'SSO') if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      redirect_to new_user_session_path,
        alert: t('devise.omniauth_callbacks.failure', kind: 'SSO', reason: 'usuário não encontrado ou inativo')
    end
  end

  def failure
    redirect_to new_user_session_path,
      alert: t('devise.omniauth_callbacks.failure', kind: 'SSO', reason: failure_message)
  end
end
