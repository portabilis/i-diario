class SchoolCalendarsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @school_calendars = apply_scopes(SchoolCalendar.ordered)

    authorize @school_calendars
  end

  def new
    @school_calendar = resource
    authorize resource
  end

  def create
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: school_calendars_path
    else
      render :new
    end
  end

  def edit
    @school_calendar = resource

    authorize resource
  end

  def update
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: school_calendars_path
    else
      render :edit
    end
  end

  def destroy
    authorize resource

    resource.destroy

    respond_with resource, location: school_calendars_path
  end

  def history
    @school_calendar = SchoolCalendar.find(params[:id])

    authorize @school_calendar

    respond_with @school_calendar
  end

  private

  def resource
    @school_calendar ||= case params[:action]
    when 'new', 'create'
      SchoolCalendar.new
    when 'edit', 'update', 'destroy'
      SchoolCalendar.find(params[:id])
    end.localized
  end

  def resource_params
    params.require(:school_calendar).permit(:year,
                                            :number_of_classes,
                                            steps_attributes: [:id,
                                                               :start_at,
                                                               :end_at,
                                                               :start_date_for_posting,
                                                               :end_date_for_posting,
                                                               :_destroy])
  end
end
