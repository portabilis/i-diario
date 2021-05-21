class Users::SessionsController < Devise::SessionsController
  before_action :check_failed_attempts, only: :create

  def check_failed_attempts
    flash.clear

    username = params["user"]["credentials"]

    return unless username

    user = User.find_by(login: username)

    return unless user

    failed_attempts = user.failed_attempts
    attempts_left = User.maximum_attempts - failed_attempts

    set_flash_message!(:error, :attempts_login, attempts_left: attempts_left) if attempts_left > 1
  end
end
