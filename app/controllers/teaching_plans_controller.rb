class TeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher

  def index
    @teaching_plans = apply_scopes(TeachingPlan).includes(:discipline, classroom: :unity)
                                                .by_teacher(current_teacher.id)
                                                .filter_from_params(filtering_params(params[:search]))

    authorize @teaching_plans

    @unities     = Unity.by_teacher(current_teacher.id).uniq.ordered
    @classrooms  = Classroom.by_teacher_id(current_teacher.id).ordered
    @disciplines = Discipline.by_teacher_id(current_teacher.id, current_school_year).ordered
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
      TeachingPlan.new(year: current_school_calendar.year)
    when 'edit', 'update', 'destroy'
      TeachingPlan.find(params[:id])
    end.localized
  end

  def filtering_params(params)
    params = {} unless params
    params.slice(:by_year,
                 :by_unity_id,
                 :by_classroom_id,
                 :by_discipline_id,
                 :by_school_term_type_id,
                 :by_school_term_type_step_id)
  end

  def resource_params
    params.require(:teaching_plan).permit(:year,
                                          :classroom_id,
                                          :discipline_id,
                                          :school_term_type_step_id,
                                          :school_term_type_id,
                                          :objectives,
                                          :content,
                                          :methodology,
                                          :evaluation,
                                          :references)
  end
end
