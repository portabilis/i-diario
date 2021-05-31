class Users::SessionsController < Devise::SessionsController

  def new
  @time = 0

  if (credentials = params.dig(:user, :credentials))
  credentials_hash = credentials_discriminator(credentials)

    if (user = User.find_by(credentials_hash))
    failed_attempts = user.failed_attempts
    attempts_left = User.maximum_attempts - failed_attempts

      if attempts_left > 1 && attempts_left != User.maximum_attempts
        set_flash_message!(:error, :attempts_login, attempts_left: attempts_left)
        @time = 2000 * failed_attempts

        elsif attempts_left == 1
          flash.clear
          flash[:alert] = I18n.t('devise.failure.last_attempt')
          @time = 2000 * failed_attempts
      end
    end
  end

  super
  end

  private

    def credentials_discriminator(credentials)
      if credentials =~ /^\d{3}\.\d{3}\.\d{3}\-\d{2}$/
        return { cpf: credentials }

      elsif credentials =~ /\A[^@\s]+@[^@\s]+\z/
        return { email: credentials }

      else
        return { login: credentials }

      end
    end
  end
