class TeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def index
    @teaching_plans = apply_scopes(TeachingPlan.by_teacher(current_teacher.id).includes(:discipline, school_calendar_step: :school_calendar, classroom: :unity))

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

  def history
    @teaching_plan = TeachingPlan.find(params[:id])

    authorize @teaching_plan

    respond_with @teaching_plan
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