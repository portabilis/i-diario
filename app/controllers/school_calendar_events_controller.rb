class SchoolCalendarEventsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10
  respond_to :json, only: [:grades, :classrooms]
  before_action :check_user_unity

  def index
    @school_calendar_events = apply_scopes(school_calendar.events).includes(:grade, :classroom)
                                                                  .ordered

    authorize @school_calendar_events
  end

  def new
    @school_calendar_event = resource
    @school_calendar_event.coverage = params[:coverage]
    @school_calendar_event.periods = Periods.list

    authorize resource
  end

  def create
    resource.assign_attributes resource_params

    authorize resource

    if resource.valid?
      SchoolCalendarEventDays.update_school_days(
        [school_calendar],
        [resource],
        action_name,
        resource.start_date,
        resource.end_date
      )
    end

    if resource.save
      respond_with resource, location: school_calendar_school_calendar_events_path
    else
      clear_invalid_dates
      render :new
    end
  end

  def edit
    @school_calendar_event = resource.localized

    authorize resource
  end

  def update
    resource.assign_attributes resource_params

    authorize resource

    if (dates_changed = resource.start_date_changed? || resource.end_date_changed?)
      old_start_date = resource.start_date_was
      old_end_date = resource.end_date_was
    end

    if resource.save
      if dates_changed
        SchoolCalendarEventDays.update_school_days(
          [school_calendar],
          [resource],
          action_name,
          old_start_date,
          old_end_date
        )
      end
      respond_with resource, location: school_calendar_school_calendar_events_path
    else
      clear_invalid_dates
      render :edit
    end
  end

  def destroy
    authorize resource

    SchoolCalendarEventDays.update_school_days(
      [school_calendar], [resource], action_name
    )

    resource.destroy

    respond_with resource, location: school_calendar_school_calendar_events_path
  end

  def history
    @school_calendar_event = resource

    authorize @school_calendar_event

    respond_with @school_calendar_event
  end

  private

  def courses
    @courses ||= Course.by_unity(@school_calendar.unity.id).ordered || {}
  end
  helper_method :courses

  def grades
    @grades ||= Grade.by_unity(school_calendar.unity.id).ordered
    @grades = @grades.by_course(@school_calendar_event.course_id) if @school_calendar_event.try(:course_id).present?
    @grades
  end
  helper_method :grades

  def classrooms
    @classrooms ||= Classroom.by_unity_and_grade(@school_calendar.unity.id, @school_calendar_event.grade_id).by_year(@school_calendar.year).ordered || {}
  end
  helper_method :classrooms

  def disciplines
    @disciplines ||= Discipline.by_unity_id(@school_calendar.unity.id, current_school_year)
                               .by_classroom(@school_calendar_event.classroom_id)
                               .grouper
                               .ordered || []
  end
  helper_method :disciplines

  def resource
    @school_calendar_event ||= case params[:action]
    when 'new', 'create'
      school_calendar.events.new
    when 'edit', 'update', 'destroy', 'history'
      school_calendar.events.find(params[:id])
    end
  end

  def resource_params
    params.require(:school_calendar_event).permit(
      :coverage, :course_id, :grade_id, :classroom_id, :discipline_id,
      :description, :start_date, :end_date, :event_type, :periods, :legend, :show_in_frequency_record
    )
  end

  def school_calendar
    @school_calendar = SchoolCalendar.find(params[:school_calendar_id])
  end

  def clear_invalid_dates
    start_date = resource_params[:start_date]
    end_date = resource_params[:end_date]

    @school_calendar_event.start_date = '' unless start_date.try(:to_date)
    @school_calendar_event.end_date = '' unless end_date.try(:to_date)
  end

  def check_user_unity
    return if show_all_unities?
    return if current_unity.try(:id) == school_calendar.unity_id

    redirect_to(school_calendars_path, alert: I18n.t('school_calendars.invalid_unity'))
  end

  def show_all_unities?
    @show_all_unities ||= current_user_role.try(:role_administrator?)
  end
  helper_method :show_all_unities?

  def current_user_role
    current_user.current_user_role || current_user.user_roles.first
  end
end
