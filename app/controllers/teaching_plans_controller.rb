class TeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def index
    @teaching_plans = apply_scopes(TeachingPlan.by_teacher(current_teacher.id).includes(:classroom, :discipline, school_calendar_step: :school_calendar))

    authorize @teaching_plans
  end

  def new
    @teaching_plan = resource

    authorize resource

    fetch_collections
  end

  def create
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: teaching_plans_path
    else
      fetch_collections

      render :new
    end
  end

  def edit
    @teaching_plan = resource
    validate_current_teacher

    authorize resource

    fetch_collections
  end

  def update
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: teaching_plans_path
    else
      fetch_collections

      render :edit
    end
  end

  def destroy
    authorize resource

    resource.destroy

    respond_with resource, location: teaching_plans_path
  end

  private

  def fetch_collections
    unity_id = @teaching_plan.classroom ? @teaching_plan.classroom.unity_id : nil
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(current_teacher.id, unity_id, @teaching_plan.classroom_id)
    fetcher.fetch!
    @unities = fetcher.unities
    @classrooms = fetcher.classrooms
    @disciplines = fetcher.disciplines
    @school_calendar_steps = SchoolCalendarStep.where(school_calendar: current_school_calendar)
  end

  def resource
    @teaching_plan ||= case params[:action]
    when 'new', 'create'
      TeachingPlan.new
    when 'edit', 'update', 'destroy'
      TeachingPlan.find(params[:id])
    end.localized
  end

  def validate_current_teacher
    unless @teaching_plan.teacher_discipline_classrooms.any? { |teacher_discipline_classroom| teacher_discipline_classroom.teacher_id.eql?(current_teacher.id) }
      flash[:alert] = t('.current_teacher_not_allowed')
      redirect_to root_path
    end
  end

  def resource_params
    params.require(:teaching_plan).permit(:classroom_id,
                                          :discipline_id,
                                          :school_calendar_step_id,
                                          :objectives,
                                          :content,
                                          :methodology,
                                          :evaluation,
                                          :references)
  end
end