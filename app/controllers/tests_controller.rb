class TestsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10
  before_action :require_teacher, only: [:new, :create, :edit, :update]
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def index
    @tests = apply_scopes(Test.includes(:unity, :classroom, :discipline, :test_setting_test).ordered)

    authorize @tests
  end

  def new
    @test = resource
    @test.school_calendar = current_school_calendar
    @test.test_setting    = current_test_setting

    authorize resource

    fetch_classrooms
  end

  def create
    resource.assign_attributes resource_params
    resource.school_calendar = current_school_calendar
    resource.test_setting    = current_test_setting

    authorize resource

    if resource.save
      respond_with resource, location: tests_path
    else
      fetch_classrooms

      render :new
    end
  end

  def edit
    @test = resource

    authorize resource

    fetch_classrooms
  end

  def update
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: tests_path
    else
      fetch_classrooms

      render :edit
    end
  end

  def destroy
    authorize resource

    resource.destroy

    respond_with resource, location: tests_path
  end

  def history
    @test = test.find(params[:id])

    authorize @test

    respond_with @test
  end

  private

  def fetch_classrooms
    if @test.unity_id
      @classrooms = Classroom.joins(:teacher_discipline_classrooms)
                              .where(unity_id: @test.unity_id, teacher_discipline_classrooms: { teacher_id: current_teacher.id})
                              .ordered
                              .uniq
    else
      @classrooms = {}
    end

    if @test.classroom_id
      @disciplines = Discipline.joins(:teacher_discipline_classrooms)
                               .where(teacher_discipline_classrooms: { teacher_id: current_teacher.id, classroom_id: @test.classroom_id})
                               .ordered
                               .uniq
    else
      @disciplines = {}
    end
  end

  def resource
    @test ||= case params[:action]
    when 'new', 'create'
      Test.new
    when 'edit', 'update', 'destroy'
      Test.find(params[:id])
    end.localized
  end

  def resource_params
    params.require(:test).permit(
      :unity_id, :classroom_id, :discipline_id, :test_date, :class_number, :test_setting_test_id, :description
    )
  end

  def require_teacher
    unless current_teacher
      flash[:alert] = t('errors.tests.require_teacher')
      redirect_to tests_path
    end
  end
end
