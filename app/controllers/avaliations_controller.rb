class AvaliationsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10, only: [:index]

  respond_to :html, :js, :json

  before_action :require_current_teacher
  before_action :require_current_school_calendar
  before_action :require_current_test_setting
  before_action :set_number_of_classes, only: [:new, :create, :edit, :update]

  def index
    current_user_unity_id = current_user_unity.id if current_user_unity

    @avaliations = apply_scopes(Avaliation).includes(:unity, :classroom, :discipline, :test_setting_test)
                                           .by_teacher(current_teacher.id)
                                           .by_unity_id(current_user_unity_id)
                                           .ordered

    authorize @avaliations

    @unities = Unity.by_teacher(current_teacher.id)
    @classrooms = Classroom.by_teacher_id(current_teacher.id)
    @disciplines = Discipline.by_teacher_id(current_teacher.id)

    respond_with @avaliations
  end

  def new
    @avaliation = resource
    @avaliation.school_calendar = current_school_calendar
    @avaliation.test_setting    = current_test_setting
    @avaliation.unity           = current_user_unity
    @avaliation.test_date       = Time.zone.today

    authorize resource

    @test_settings = TestSetting.where(year: current_school_calendar.year).ordered
  end

  def create
    resource.localized.assign_attributes(resource_params)
    resource.school_calendar = current_school_calendar

    authorize resource

    if resource.save
      respond_with resource, location: avaliations_path
    else
      @test_settings = TestSetting.where(year: current_school_calendar.year).ordered

      render :new
    end
  end

  def edit
    @avaliation = resource

    authorize @avaliation

    @test_settings = TestSetting.where(year: current_school_calendar.year).ordered
  end

  def update
    @avaliation = resource
    @avaliation.localized.assign_attributes(resource_params)

    authorize @avaliation

    if resource.save
      respond_with @avaliation, location: avaliations_path
    else
      @test_settings = TestSetting.where(year: current_school_calendar.year).ordered

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

  def search
    @avaliations = apply_scopes(Avaliation).ordered

    render json: @avaliations
  end

  def show
    render json: resource
  end

  private

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def resource
    @avaliation ||= case params[:action]
    when 'new', 'create'
      Avaliation.new
    when 'edit', 'update', 'destroy', 'show'
      Avaliation.find(params[:id])
    end
  end

  def resource_params
    params.require(:avaliation).permit(:test_setting_id,
                                       :unity_id,
                                       :classroom_id,
                                       :discipline_id,
                                       :test_date,
                                       :classes,
                                       :description,
                                       :test_setting_test_id,
                                       :weight,
                                       :observations)
  end
end
