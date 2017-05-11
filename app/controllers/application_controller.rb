require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html

  include BootstrapFlashHelper
  include Pundit
  skip_around_filter :set_locale_from_url
  around_action :handle_customer

  respond_to :html, :json

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

  before_action :check_entity_status
  before_action :authenticate_user!, unless: :disabled_entity_page?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_for_***REMOVED***
  before_action :check_for_current_user_role

  has_scope :q do |controller, scope, value|
    scope.search(value).limit(10)
  end

  has_scope :filter, type: :hash do |controller, scope, value|
   filters = value.select { |filter_name, filter_value| filter_value.present? }
   filters.each do |filter_name, filter_value|
     scope = scope.send(filter_name, filter_value)
   end

   scope
 end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from IeducarApi::Base::ApiError, with: :rescue_from_api_error

  protected

  def page
    params[:page] || 1
  end

  def per
    params[:per] || 10
  end

  def policy(record)
    begin
      Pundit::PolicyFinder.new(record).policy!.new(current_user, record)
    rescue
      ApplicationPolicy.new(current_user, record)
    end
  end
  helper_method :policy

  def handle_customer(&block)
    if current_entity
      current_entity.using_connection(&block)
    else
      redirect_to '/404'
    end
  end

  def check_entity_status
    if current_entity.disabled
      redirect_to disabled_entity_path unless disabled_entity_page?
    end
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

  def after_sign_in_path_for(resource_or_scope)
    if !!current_user.receive_news == current_user.receive_news
      super
    else
      flash[:info] = "É importante que seu cadastro no sistema esteja atualizado. Desta forma você poderá receber novidades sobre o produto. Por favor, atualize aqui suas preferências de e-mail."
      edit_account_path
    end
  end

  def check_for_***REMOVED***
    return unless current_user

    if synchronization = current_user.synchronizations.completed_unnotified
      flash.now[:notice] = t("ieducar_api_synchronization.completed")
      synchronization.notified!
    elsif synchronization = current_user.synchronizations.last_error
      flash.now[:alert] = t("ieducar_api_synchronization.error", error: synchronization.error_message)
      synchronization.notified!
    end
  end

  def check_for_current_user_role
    return unless current_user

    if !valid_current_role?
      flash.now[:warning] = t("current_role.check.warning")
    end
  end

  def current_entity_configuration
    @current_entity_configuration ||= EntityConfiguration.first
  end
  helper_method :current_entity_configuration

  def current_entity
    @current_entity ||= Entity.find_by(domain: request.host)
    Entity.current = @current_entity
  end
  helper_method :current_entity

  def current_configuration
    @configuration ||= IeducarApiConfiguration.current
  end
  helper_method :current_configuration

  def current_notification
    @configuration ||= Notification.current
  end
  helper_method :current_notification

  def api
    @api ||= IeducarApi::StudentRegistrations.new(current_configuration.to_api)
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(root_path)
  end

  def rescue_from_api_error(exception)
    redirect_to edit_ieducar_api_configurations_path, alert: exception.message
  end

  def current_teacher
    current_user.try(:current_teacher)
  end
  helper_method :current_teacher

  def current_teacher_id
    current_teacher.try(:id)
  end
  helper_method :current_teacher_id

  def current_school_calendar
    return if current_user.admin? && current_user_unity.blank?

    CurrentSchoolCalendarFetcher.new(current_user_unity, current_user_classroom).fetch
  end

  def current_test_setting
    CurrentTestSettingFetcher.new(current_school_calendar).fetch
  end

  def require_current_teacher
    unless current_teacher
      flash[:alert] = t('errors.general.require_current_teacher')
      redirect_to root_path
    end
  end

  def require_current_teacher_discipline_classrooms
    unless current_teacher && current_teacher.teacher_discipline_classrooms.any?
      flash[:alert] = t('errors.general.require_current_teacher_discipline_classrooms')
      redirect_to root_path
    end
  end

  def require_current_school_calendar
    unless current_school_calendar
      flash[:alert] = t('errors.general.require_current_school_calendar')
      redirect_to root_path
    end
  end

  def require_current_test_setting
    unless current_test_setting
      flash[:alert] = t('errors.general.require_current_test_setting')
      redirect_to root_path
    end
  end

  def current_user_unity
    current_user.current_user_role.try(:unity) || current_user.current_unity
  end
  helper_method :current_user_unity

  def current_user_classroom
    current_user.try(:current_classroom)
  end
  helper_method :current_user_classroom

  def current_user_discipline
    current_user.try(:current_discipline)
  end
  helper_method :current_user_discipline

  def valid_current_role?
    CurrentRoleForm.new(
      current_user_id: current_user.id,
      current_user_role_id: current_user.current_user_role_id,
      teacher_id: current_user.teacher_id,
      current_classroom_id: current_user.current_classroom_id,
      current_discipline_id: current_user.current_discipline_id,
      current_unity_id: current_user.current_unity_id,
      assumed_teacher_id: current_user.assumed_teacher_id
    ).valid?
  end
  helper_method :valid_current_role?

  def current_user_is_parent?
    current_user && current_user.current_user_role && current_user.current_user_role.role_parent?
  end
  helper_method :current_user_is_parent?


  private

  def disabled_entity_page?
    controller_name.eql?('pages') && action_name.eql?('disabled_entity')
  end
end
