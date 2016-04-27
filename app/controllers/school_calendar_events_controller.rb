class SchoolCalendarEventsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10
  respond_to :json, only: [:grades, :classrooms]

  def index
    @grades = Grade.by_unity(school_calendar.unity.id).ordered
    @school_calendar_events = apply_scopes(school_calendar.events).includes(:grade, :classroom)
                                                                  .filter(filtering_params(params[:search]))
                                                                  .ordered

    authorize @school_calendar_events
  end

  def new
    @school_calendar_event = resource
    @school_calendar_event.coverage = params[:coverage]
    fetch_courses
    authorize resource
  end

  def create
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: school_calendar_school_calendar_events_path
    else
      fetch_courses
      render :new
    end
  end

  def edit
    @school_calendar_event = resource
    fetch_courses

    authorize resource
  end

  def update
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: school_calendar_school_calendar_events_path
    else
      fetch_courses
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

  def grades
    @grades = Grade.by_unity(school_calendar.unity.id).where(course_id: params[:course_id]).ordered
    respond_with(grades: @grades)
  end

  def classrooms
    @classrooms = Classroom.by_unity_and_grade(school_calendar.unity.id, params[:grade_id]).by_year(school_calendar.year).ordered
    respond_with(classrooms: @classrooms)
  end

  private

  def filtering_params(params)
    params = {} unless params
    params.slice(:by_date, :by_description, :by_type, :by_grade, :by_classroom)
  end

  def fetch_courses
    if @school_calendar_event.coverage != CoveragesOfEvent::BY_UNITY
      @courses = []
      @courses = Course.by_unity(@school_calendar.unity.id).ordered
      @grades = []
      if @school_calendar_event.course_id.present?
        @grades = Grade.by_unity(@school_calendar.unity.id).where(course_id: @school_calendar_event.course_id).ordered
      end
      @classrooms = []
      if @school_calendar_event.grade_id.present?
        @classrooms = Classroom.by_unity_and_grade(@school_calendar.unity.id, @school_calendar_event.grade_id).by_year(@school_calendar.year).ordered
      end
    end
  end

  def resource
    @school_calendar_event ||= case params[:action]
    when 'new', 'create'
      school_calendar.events.new
    when 'edit', 'update', 'destroy', 'history'
      school_calendar.events.find(params[:id])
    end.localized
  end

  def resource_params
    params.require(:school_calendar_event).permit(
      :coverage, :course_id, :grade_id, :classroom_id,
      :description, :event_date, :event_type
    )
  end

  def school_calendar
    @school_calendar = SchoolCalendar.find(params[:school_calendar_id])
  end
end
