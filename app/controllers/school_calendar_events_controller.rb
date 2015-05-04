class SchoolCalendarEventsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @school_calendar_events = apply_scopes(school_calendar.events.ordered)

    authorize @school_calendar_events
  end

  def new
    @school_calendar_event = resource
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
    @school_calendar_event = resource

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
      :description, :event_date, :event_type
    )
  end

  def school_calendar
    @school_calendar = SchoolCalendar.find(params[:school_calendar_id])
  end
end
