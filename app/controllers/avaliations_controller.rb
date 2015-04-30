class AvaliationsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10
  before_action :require_teacher, only: [:new, :create, :edit, :update]
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def index
    @avaliations = apply_scopes(Avaliation.includes(:unity, :classroom, :discipline, :test_setting_test).ordered)

    authorize @avaliations
  end

  def new
    @avaliation = resource
    @avaliation.school_calendar = current_school_calendar
    @avaliation.test_setting    = current_test_setting

    authorize resource

    fetch_classrooms
  end

  def create
    resource.assign_attributes resource_params
    resource.school_calendar = current_school_calendar
    resource.test_setting    = current_test_setting

    authorize resource

    if resource.save
      respond_with resource, location: avaliations_path
    else
      fetch_classrooms

      render :new
    end
  end

  def edit
    @avaliation = resource

    authorize resource

    fetch_classrooms
  end

  def update
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: avaliations_path
    else
      fetch_classrooms

      render :edit
    end
  end

  def destroy
    authorize resource

    resource.destroy

    respond_with resource, location: avaliations_path
  end

  def history
    @avaliation = Avaliation.find(params[:id])

    authorize @avaliation

    respond_with @avaliation
  end

  private

  def fetch_classrooms
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, @avaliation.unity_id, @avaliation.classroom_id)
    fetcher.fetch!
    @unities = fetcher.unities
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
  end

  def resource
    @avaliation ||= case params[:action]
    when 'new', 'create'
      Avaliation.new
    when 'edit', 'update', 'destroy'
      Avaliation.find(params[:id])
    end.localized
  end

  def resource_params
    params.require(:avaliation).permit(
      :unity_id, :classroom_id, :discipline_id, :test_date, :class_number, :test_setting_test_id, :description
    )
  end

  def require_teacher
    unless current_teacher
      flash[:alert] = t('errors.avaliations.require_teacher')
      redirect_to avaliations_path
    end
  end
end
