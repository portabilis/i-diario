class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :passport

  SSO_USER_NOT_FOUND_EVENT = 'passport.user_not_found'.freeze

  def passport
    auth = request.env['omniauth.auth']
    @user = find_or_provision_user(auth)

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

  private

  def find_or_provision_user(auth)
    email = auth&.dig('info', 'email')
    user = User.find_by(email: email)

    return user if user.present?

    ActiveSupport::Notifications.instrument(SSO_USER_NOT_FOUND_EVENT, email: email, auth: auth)
    User.find_by(email: email)
  end
end
