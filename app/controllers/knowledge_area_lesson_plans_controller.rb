class KnowledgeAreaLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def index
    @knowledge_area_lesson_plans = apply_scopes(KnowledgeAreaLessonPlan)
      .includes(
        :knowledge_areas,
        lesson_plan: [:unity, :classroom]
      )
      .filter(filtering_params(params[:search]))
      .by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
      .ordered

    authorize @knowledge_area_lesson_plans

    @classrooms = Classroom.by_unity_and_teacher(
        current_user_unity.id,
        current_teacher.id
      )
      .ordered
    @knowledge_areas = KnowledgeArea.all
  end

  def new
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.new.localized
    @knowledge_area_lesson_plan.build_lesson_plan
    @knowledge_area_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @knowledge_area_lesson_plan.lesson_plan.unity = current_user_unity

    authorize @knowledge_area_lesson_plan

    @unities = Unity.by_teacher(current_teacher.id).ordered
    @classrooms =  Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id).ordered
    @knowledge_areas = KnowledgeArea.all
  end

  def create
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.new.localized
    @knowledge_area_lesson_plan.assign_attributes(resource_params)
    @knowledge_area_lesson_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')
    @knowledge_area_lesson_plan.lesson_plan.school_calendar = current_school_calendar

    authorize @knowledge_area_lesson_plan

    if @knowledge_area_lesson_plan.save
      respond_with @knowledge_area_lesson_plan, location: knowledge_area_lesson_plans_path
    else
      @unities = Unity.by_teacher(current_teacher.id).ordered
      @classrooms =  Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id).ordered
      @knowledge_areas = KnowledgeArea.all

      render :new
    end
  end

  def edit
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id]).localized

    authorize @knowledge_area_lesson_plan

    @unities = Unity.by_teacher(current_teacher.id).ordered
    @classrooms =  Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id).ordered
    @knowledge_areas = KnowledgeArea.all
  end

  def update
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id]).localized
    @knowledge_area_lesson_plan.assign_attributes(resource_params)
    @knowledge_area_lesson_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')

    authorize @knowledge_area_lesson_plan

    if @knowledge_area_lesson_plan.save
      respond_with @knowledge_area_lesson_plan, location: knowledge_area_lesson_plans_path
    else
      @unities = Unity.by_teacher(current_teacher.id).ordered
      @classrooms =  Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id).ordered
      @knowledge_areas = KnowledgeArea.all

      render :edit
    end
  end

  def destroy
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id])

    @knowledge_area_lesson_plan.destroy

    respond_with @knowledge_area_lesson_plan, location: knowledge_area_lesson_plans_path
  end

  private

  def resource_params
    params.require(:knowledge_area_lesson_plan).permit(
      :lesson_plan_id,
      :knowledge_area_ids,
      lesson_plan_attributes: [
        :id,
        :school_calendar_id,
        :unity_id,
        :classroom_id,
        :lesson_plan_date,
        :contents,
        :activities,
        :objectives,
        :resources,
        :evaluation,
        :bibliography,
        :opinion
      ]
    )
  end

  def filtering_params(params)
    params = {} unless params
    params.slice(
      :by_classroom_id,
      :by_knowledge_area_id,
      :by_lesson_plan_date
    )
  end
end
