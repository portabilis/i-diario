class Users::PasswordsController < Devise::PasswordsController
  prepend_before_action :verify_recaptcha?, only: :create
end
