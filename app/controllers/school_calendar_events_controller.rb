class SchoolCalendarEventsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10
  respond_to :json, only: [:grades, :classrooms]

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

    if resource.save
      respond_with resource, location: school_calendar_school_calendar_events_path
    else
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

    if resource.save
      respond_with resource, location: school_calendar_school_calendar_events_path
    else
      render :edit
    end
  end

  def destroy
    authorize resource

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
    @disciplines ||= Discipline.by_unity_id(@school_calendar.unity.id).by_classroom(@school_calendar_event.classroom_id).ordered || []
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
      :description, :start_date, :end_date, :event_type, :periods, :legend
    )
  end

  def school_calendar
    @school_calendar = SchoolCalendar.find(params[:school_calendar_id])
  end
end
