class SchoolCalendarEventBatchesController < ApplicationController
  after_action :school_calendars_days, only: [:create, :update, :create_or_update_batch, :destroy]
  before_action :school_calendars, only: [:destroy, :destroy_batch]
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @school_calendar_event_batches = apply_scopes(SchoolCalendarEventBatch).ordered

    authorize @school_calendar_event_batches
  end

  def new
    @school_calendar_event_batch = SchoolCalendarEventBatch.new

    authorize @school_calendar_event_batch
  end

  def create
    @school_calendar_event_batch = SchoolCalendarEventBatch.new(resource_params)
    @school_calendar_event_batch.batch_status = BatchStatus::STARTED

    authorize @school_calendar_event_batch

    if @school_calendar_event_batch.save
      create_or_update_batch(@school_calendar_event_batch.id)

      respond_with @school_calendar_event_batch, location: school_calendar_event_batches_path
    else
      render :new
    end
  end

  def edit
    @school_calendar_event_batch = SchoolCalendarEventBatch.find(params[:id])

    authorize @school_calendar_event_batch
  end

  def update
    @school_calendar_event_batch = SchoolCalendarEventBatch.find(params[:id])
    @school_calendar_event_batch.assign_attributes(resource_params)
    @school_calendar_event_batch.batch_status = BatchStatus::STARTED

    if @school_calendar_event_batch.save
      create_or_update_batch(@school_calendar_event_batch.id)

      respond_with @school_calendar_event_batch, location: school_calendar_event_batches_path
    else
      render :edit
    end
  end

  def destroy
    school_calendar_event_batch = SchoolCalendarEventBatch.find(params[:id])

    authorize school_calendar_event_batch

    school_calendar_event_batch.update(batch_status: BatchStatus::STARTED)

    destroy_batch(school_calendar_event_batch.id)

    respond_with school_calendar_event_batch, location: school_calendar_event_batches_path
  end

  def school_calendar_years
    years = []

    Unity.with_api_code
         .joins(:school_calendars)
         .pluck('school_calendars.year')
         .uniq
         .compact
         .sort
         .reverse_each do |year|
      years << OpenStruct.new(id: year, text: year, name: year)
    end

    years
  end
  helper_method :school_calendar_years

  private

  def school_calendars_days
    SchoolCalendarEventDays.new(school_calendars, school_calendar_event_batch.school_calendar_events, action_name)
                           .update_school_days(school_calendar_event_batch.start_date, school_calendar_event_batch.end_date)
  end

  def school_calendars
    school_calendars_ids = school_calendar_event_batch.school_calendar_events.map(&:school_calendar_id)

    SchoolCalendar.includes(:events).where(id: school_calendars_ids)
  end

  def resource_params
    parameters = params.require(:school_calendar_event_batch).permit(
      :year, :periods, :description, :start_date, :end_date, :event_type, :legend, :show_in_frequency_record
    )

    parameters[:periods] = parameters[:periods].split(',')
    parameters
  end

  def create_or_update_batch(school_calendar_event_batch_id)
    SchoolCalendarEventBatchManager::EventCreatorWorker.perform_in(
      1.second,
      current_entity.id,
      school_calendar_event_batch_id,
      current_user.id
    )
  end

  def destroy_batch(school_calendar_event_batch_id)
    SchoolCalendarEventBatchManager::EventDestroyerWorker.perform_in(
      1.second,
      current_entity.id,
      school_calendar_event_batch_id,
      current_user.id
    )
  end

  def school_calendar_event_batch
    @school_calendar_event_batch ||= SchoolCalendarEventBatch.find(params[:id])
  end
end
