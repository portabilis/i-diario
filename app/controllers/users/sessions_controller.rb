class Users::SessionsController < Devise::SessionsController
  def new
    @time = 0
    if failed_login?
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

    super
  end

  private

  def failed_login?
    (options = env["warden.options"]) && options[:action] == "unauthenticated"
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
