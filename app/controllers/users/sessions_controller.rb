class Users::SessionsController < Devise::SessionsController
  prepend_before_action :verify_recaptcha?, only: :create, unless: :request_xhr?

  private

  def request_xhr?
    request.xhr?
  end
end
