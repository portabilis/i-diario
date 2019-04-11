require "application_responder"

class ApplicationController < ActionController::Base
  MAX_STEPS_FOR_SCHOOL_CALENDAR = 4

  self.responder = ApplicationResponder
  respond_to :html

  include BootstrapFlashHelper
  include Pundit
  skip_around_filter :set_locale_from_url
  around_action :handle_customer
  before_action :set_honeybadger_context
  around_filter :set_user_current
  around_filter :set_thread_origin_type

  respond_to :html, :json

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

  before_action :check_entity_status
  before_action :authenticate_user!, unless: :disabled_entity_page?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_for_notifications
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

  def check_for_notifications
    return unless current_user

    if synchronization = current_user.synchronizations.completed_unnotified
      flash.now[:notice] = t("ieducar_api_synchronization.completed")
      synchronization.notified!
    elsif synchronization = current_user.synchronizations.last_error
      flash.now[:alert] = t(
        "ieducar_api_synchronization.error",
        error: current_user.admin? && synchronization.full_error_message.present? ?
               synchronization.full_error_message :
               synchronization.error_message
      )
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

    CurrentSchoolCalendarFetcher.new(current_user_unity, current_user_classroom, current_user_school_year).fetch
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

  def require_current_test_setting
    unless current_test_setting
      flash[:alert] = t('errors.general.require_current_test_setting')
      redirect_to root_path
    end
  end

  def require_valid_school_calendar(school_calendar)
    if school_calendar.steps.count > MAX_STEPS_FOR_SCHOOL_CALENDAR
      flash[:alert] = I18n.t('errors.general.school_calendar_steps_more_than_limit', unity: current_user_unity)
      redirect_to root_path
    end
  end

  def can_change_school_year?
    @can_change_school_year ||= current_user.can_change_school_year?
  end
  helper_method :can_change_school_year?

  def current_user_unity
    @current_user_unity ||= current_user.current_unity
  end
  helper_method :current_user_unity

  def current_user_classroom
    @current_user_classroom ||= current_user.try(:current_classroom)
  end
  helper_method :current_user_classroom

  def current_user_discipline
    @current_user_discipline ||= current_user.try(:current_discipline)
  end
  helper_method :current_user_discipline

  def current_user_available_years
    return [] unless current_user_unity
    @current_user_available_years ||= begin
      YearsFromUnityFetcher.new(current_user_unity.id).fetch.map{|year| { id: year, name: year }}
    end
  end
  helper_method :current_user_available_years

  def current_user_available_teachers
    return [] unless current_user_unity
    @current_user_available_teachers ||= begin
      teachers = Teacher.by_unity_id(current_user_unity).order_by_name
      if current_school_calendar.try(:year)
        teachers.by_year(current_school_calendar.try(:year))
      else
        teachers
      end
    end
  end
  helper_method :current_user_available_teachers

  def current_user_available_classrooms
    return [] unless current_user_unity && current_teacher
    @current_user_available_classrooms ||= begin
      classrooms = Classroom.by_unity_and_teacher(current_user_unity, current_teacher).ordered
      if current_school_calendar.try(:year)
        classrooms.by_year(current_school_calendar.try(:year))
      else
        classrooms
      end
    end
  end
  helper_method :current_user_available_classrooms

  # @TODO refatorar index do discipline em service e utilizar em ambos
  def current_user_available_disciplines
    return [] unless current_user_classroom && current_teacher

    @current_user_available_disciplines ||= Discipline.by_teacher_id(current_teacher)
                               .by_classroom(current_user_classroom)
                               .ordered
  end
  helper_method :current_user_available_disciplines

  def current_unities
    @current_unities ||=
      if current_user.current_user_role.try(:role_administrator?)
        Unity.ordered
      else
        [current_user_unity]
      end
  end
  helper_method :current_unities

  def current_user_school_year
    current_user.try(:current_school_year)
  end
  helper_method :current_user_school_year

  def valid_current_role?
    CurrentRoleForm.new(
      current_user_id: current_user.id,
      current_user_role_id: current_user.current_user_role_id,
      teacher_id: current_user.teacher_id,
      current_classroom_id: current_user.current_classroom_id,
      current_discipline_id: current_user.current_discipline_id,
      current_unity_id: current_user.current_unity_id,
      assumed_teacher_id: current_user.assumed_teacher_id,
      current_school_year: current_user.current_school_year
    ).valid?
  end
  helper_method :valid_current_role?

  def teacher_discipline_score_type
    return DisciplineScoreTypes::NUMERIC if current_user_classroom.exam_rule.score_type == ScoreTypes::NUMERIC
    return DisciplineScoreTypes::CONCEPT if current_user_classroom.exam_rule.score_type == ScoreTypes::CONCEPT
    TeacherDisciplineClassroom.find_by(teacher: current_teacher, discipline: current_user_discipline).score_type if current_user_classroom.exam_rule.score_type == ScoreTypes::NUMERIC_AND_CONCEPT
  end

  def current_user_is_employee_or_administrator?
    current_user.assumed_teacher_id.blank? && current_user_role_is_employee_or_administrator?
  end
  helper_method :current_user_is_employee_or_administrator?

  def current_user_role_is_employee_or_administrator?
    current_user.current_user_role.role_employee? || current_user.current_user_role.role_administrator?
  end
  helper_method :current_user_role_is_employee_or_administrator?

  def teacher_differentiated_discipline_score_type
    exam_rule = current_user_classroom.exam_rule
    differentiated_exam_rule = exam_rule.differentiated_exam_rule
    return teacher_discipline_score_type unless differentiated_exam_rule.present?
    return teacher_discipline_score_type unless current_user_classroom.has_differentiated_students?
    return DisciplineScoreTypes::NUMERIC if differentiated_exam_rule.score_type == ScoreTypes::NUMERIC
    return DisciplineScoreTypes::CONCEPT if differentiated_exam_rule.score_type == ScoreTypes::CONCEPT
    TeacherDisciplineClassroom.find_by(teacher: current_teacher, discipline: current_user_discipline).score_type if differentiated_exam_rule.score_type == ScoreTypes::NUMERIC_AND_CONCEPT
  end

  def set_user_current
    User.current = current_user
    begin
        yield
    ensure
        User.current = nil
    end
  end

  def set_thread_origin_type
    Thread.current[:origin_type] = OriginTypes::WEB
    begin
        yield
    ensure
        Thread.current[:origin_type] = nil
    end
  end

  private

  def disabled_entity_page?
    controller_name.eql?('pages') && action_name.eql?('disabled_entity')
  end

  def set_honeybadger_context
    Honeybadger.context(
      entity: current_entity.try(:name),
      classroom_id: params[:classroom_id],
      teacher_id: params[:teacher_id],
      discipline_id: params[:discipline_id]
    )
  end

  def send_pdf(prefix, pdf_to_s)
    name = report_name(prefix)
    File.open("#{Rails.root}/public#{name}", 'wb') do |f|
      f.write(pdf_to_s)
    end
    redirect_to name
  end

  def report_name(prefix)
    "/relatorios/#{prefix}-#{SecureRandom.hex}.pdf"
  end

end
