class Users::SessionsController < Devise::SessionsController
  prepend_before_action :verify_recaptcha?, only: :create, unless: :allowed_api_header?
end
