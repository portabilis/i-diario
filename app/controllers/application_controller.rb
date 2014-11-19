require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html

  include Pundit
  skip_around_filter :set_locale_from_url
  around_action :handle_customer

  respond_to :html, :json

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_for_***REMOVED***

  protected

  def page
    params[:page] || 1
  end

  def per
    params[:per] || 10
  end

  def policy(record)
    Pundit::PolicyFinder.new(record).policy!.new(current_user, record)
  end
  helper_method :policy

  def handle_customer(&block)
    current_entity.using_connection(&block)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_in) do |u|
      u.permit(:credentials, :password, :remember_me)
    end

    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:email, :first_name, :last_name, :login, :phone, :cpf, :current_password, :authorize_email_and_sms)
    end

    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:email, :password, :password_confirmation)
    end
  end

  def check_for_***REMOVED***
    return unless current_user

    if syncronization = current_user.syncronizations.completed_unnotified
      flash.now[:notice] = t("ieducar_api_syncronization.completed")
      syncronization.notified!
    elsif syncronization = current_user.syncronizations.last_error
      flash.now[:alert] = t("ieducar_api_syncronization.error", error: syncronization.error_message)
      syncronization.notified!
    end
  end

  def current_entity
    @current_entity ||= Entity.find_by(domain: request.host)
  end
  helper_method :current_entity

  def current_configuration
    @configuration ||= IeducarApiConfiguration.current
  end
  helper_method :current_configuration

  def api
    @api ||= IeducarApi::StudentRegistrations.new(current_configuration.to_api)
  end
end
