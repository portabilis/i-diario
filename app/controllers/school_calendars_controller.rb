class SchoolCalendarsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10
  before_action :check_user_unity, only: [:edit, :update, :destroy]

  def index
    @school_calendars = apply_scopes(SchoolCalendar).includes(:unity)
                                                    .filter_from_params(filtering_params(params[:search]))
                                                    .ordered

    unless show_all_unities?
      @school_calendars = @school_calendars.by_unity_id(current_unity)
    end

    authorize @school_calendars

    @unities = Unity.ordered
  end

  def edit
    @school_calendar = resource

    authorize resource
  end

  def update
    resource.assign_attributes(resource_params.to_h)

    authorize resource

    if resource.save
      respond_with resource, location: school_calendars_path
    else
      render :edit
    end
  end

  def destroy
    authorize resource

    resource_destroyer = ResourceDestroyer.new.destroy(resource)

    if resource_destroyer.has_error?
      flash[:error] = resource_destroyer.error_message
      flash[:notice] = ""
    end

    respond_with resource, location: school_calendars_path
  end

  def history
    @school_calendar = SchoolCalendar.find(params[:id])

    authorize @school_calendar

    respond_with @school_calendar
  end

  def years_from_unity
    only_opened_years = ActiveRecord::Type::Boolean.new.cast(params[:only_opened_years])
    @years = YearsFromUnityFetcher.new(params[:unity_id], only_opened_years).fetch.map { |year|
      { id: year, name: year }
    }

    render json: @years
  end

  def step
    classroom = Classroom.find(params[:classroom_id])
    @step = StepsFetcher.new(classroom).step_by_id(params[:step_id])

    render json: @step.to_json
  end

  private

  def filtering_params(params)
    params = {} unless params
    params.slice(:by_year, :by_unity_id)
  end

  def resource
    @school_calendar ||= case params[:action]
    when 'new', 'create'
      SchoolCalendar.new
    when 'edit', 'update', 'destroy'
      SchoolCalendar.find(params[:id])
    end
  end

  def resource_params
    params.require(:school_calendar).permit(
      :year,
      :number_of_classes,
      steps_attributes: [
        :id,
        :step_number,
        :start_at,
        :end_at,
        :start_date_for_posting,
        :end_date_for_posting,
        :_destroy
      ],
      classrooms_attributes: [
        :id,
        :classroom,
        :_destroy,
        classroom_steps_attributes: [
          :id,
          :step_number,
          :start_at,
          :end_at,
          :start_date_for_posting,
          :end_date_for_posting
        ]
      ]
    )
  end

  def check_user_unity
    return if show_all_unities?
    return if current_unity.try(:id) == resource.unity_id

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
