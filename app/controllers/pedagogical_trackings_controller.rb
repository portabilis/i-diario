class PedagogicalTrackingsController < ApplicationController
  before_action :require_current_year
  before_action :minimum_year
  before_action :set_default_date

  def index
    calculator = PedagogicalTrackingCalculator.new(
      entity: @current_entity,
      year: current_user_school_year,
      current_user: current_user,
      params: params,
      employee_unities: employee_unities
    )

    data = calculator.calculate_index_data

    if data[:updated_at]
      @updated_at = data[:updated_at][:date]
      @updated_at_hour = data[:updated_at][:hour]
    end

    @school_days = data[:school_days]
    @school_frequency_done_percentage = data[:school_frequency_done_percentage]
    @school_content_record_done_percentage = data[:school_content_record_done_percentage]
    @unknown_teachers = data[:unknown_teachers]
    @percents = data[:percents]
    @start_date = data[:start_date]
    @end_date = data[:end_date]

    if data[:unity_id]
      @partial = :classrooms
      @classrooms = Classroom.where(unity_id: data[:unity_id], year: current_user_school_year).ordered
    else
      @partial = :schools
    end
  end

  def teachers
    unity_id = params[:unity_id]
    classroom_id = params[:classroom_id]
    teacher_id = params[:teacher_id]
    start_date = params[:start_date].try(:to_date)
    end_date = params[:end_date].try(:to_date)

    calculator = PedagogicalTrackingCalculator.new(
      entity: @current_entity,
      year: current_user_school_year,
      current_user: current_user,
      params: params
    )

    @teacher_percents = calculator.calculate_teachers_data(
      unity_id: unity_id,
      classroom_id: classroom_id,
      teacher_id: teacher_id,
      start_date: start_date,
      end_date: end_date,
      filter_params: params.slice(
        :frequency_operator,
        :frequency_percentage,
        :content_record_operator,
        :content_record_percentage
      )
    )

    respond_with @teacher_percents
  end

  private

  def minimum_year
    return if current_user_school_year >= 2020

    flash[:alert] = t('pedagogical_trackings.minimum_year.error')
    redirect_to root_path
  end

  def employee_unities
    return unless current_user.employee?

    roles_ids = Role.where(access_level: AccessLevel::EMPLOYEE).pluck(:id)
    unities_ids = UserRole.where(user_id: current_user.id, role_id: roles_ids).pluck(:unity_id)
    @employee_unities ||= Unity.find(unities_ids)
  end
  helper_method :employee_unities

  def all_unities
    @all_unities ||= Unity.joins(:school_calendars)
                          .where(school_calendars: { year: current_user_school_year })
                          .ordered
  end
  helper_method :all_unities

  def set_default_date
    @start_date = (params[:start_date] ||= current_school_calendar.first_day)
    @end_date = (params[:end_date] ||= current_school_calendar.last_day)
  end
end