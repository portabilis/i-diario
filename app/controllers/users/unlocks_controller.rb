class Users::UnlocksController < Devise::UnlocksController
  prepend_before_action :verify_recaptcha?, only: :create
end
