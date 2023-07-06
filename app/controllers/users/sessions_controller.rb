class Users::SessionsController < Devise::SessionsController
  def new
    @time = 0
    if password_blank? && user_login_not_blank?
      flash.now[:alert] = I18n.t('devise.failure.password_blank')
    elsif failed_login? && user_login_not_blank?
      valid_failed_attempts
    end

    super
  end

  def password_blank?
    password = params[:user][:password] if params[:user].present?
    password.blank?
  end

  def user_login_not_blank?
    user = params[:user][:credentials] if params[:user].present?
    user.present?
  end

  def valid_failed_attempts
    credentials = params.dig(:user, :credentials)
    credentials_hash = credentials_discriminator(credentials)

    if (user = User.find_by(credentials_hash))
      failed_attempts = user.failed_attempts
      user.update_status(UserStatus::PENDING) if failed_attempts == User.maximum_attempts
      attempts_left = User.maximum_attempts - failed_attempts

      if attempts_left > 1 && attempts_left != User.maximum_attempts
        flash.now[:error] = I18n.t('devise.sessions.user.attempts_login', attempts_left: attempts_left)
        @time = 2000 * failed_attempts

      elsif attempts_left == 1
        flash.clear
        flash.now[:alert] = I18n.t('devise.failure.last_attempt')
        @time = 2000 * failed_attempts
      end
    end
  end

  private

  def failed_login?
    (options = request.env["warden.options"]) && options[:action] == "unauthenticated"
  end

  def credentials_discriminator(credentials)
    key = case credentials
          when /^\d{3}\.?\d{3}\.?\d{3}\-?\d{2}$/ then :cpf
          when /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i then :email
          else :login
          end

    Hash[key, credentials]
  end
end
