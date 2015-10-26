class KnowledgeAreaLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def index
    @knowledge_area_lesson_plans = apply_scopes(KnowledgeAreaLessonPlan)
      .select(
        KnowledgeAreaLessonPlan.arel_table[Arel.sql('*')],
        LessonPlan.arel_table[:lesson_plan_date]
      )
      .includes(:knowledge_areas, lesson_plan: [:unity, :classroom])
      .filter(filtering_params(params[:search]))
      .by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
      .uniq
      .ordered

    authorize @knowledge_area_lesson_plans

    @classrooms = fetch_classrooms
    @knowledge_areas = fetch_knowledge_area
  end

  def show
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id]).localized

    authorize @knowledge_area_lesson_plan

    respond_with @knowledge_area_lesson_plan do |format|
      format.pdf do
        knowledge_area_lesson_plan_pdf = KnowledgeAreaLessonPlanPdf.build(
          current_entity_configuration,
          @knowledge_area_lesson_plan
        )

        send_data(
          knowledge_area_lesson_plan_pdf.render,
          filename: 'planos-de-aula-por-area-de-conhecimento.pdf',
          type: 'application/pdf',
          disposition: 'inline'
        )
      end
    end
  end

  def new
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.new.localized
    @knowledge_area_lesson_plan.build_lesson_plan
    @knowledge_area_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @knowledge_area_lesson_plan.lesson_plan.unity = current_user_unity
    @knowledge_area_lesson_plan.lesson_plan.lesson_plan_date = Date.today

    authorize @knowledge_area_lesson_plan

    @unities = fetch_unities
    @classrooms =  fetch_classrooms
    @knowledge_areas = fetch_knowledge_area
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
      @unities = fetch_unities
      @classrooms =  fetch_classrooms
      @knowledge_areas = fetch_knowledge_area

      render :new
    end
  end

  def edit
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id]).localized

    authorize @knowledge_area_lesson_plan

    @unities = fetch_unities
    @classrooms =  fetch_classrooms
    @knowledge_areas = fetch_knowledge_area
  end

  def update
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id]).localized
    @knowledge_area_lesson_plan.assign_attributes(resource_params)
    @knowledge_area_lesson_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')

    authorize @knowledge_area_lesson_plan

    if @knowledge_area_lesson_plan.save
      respond_with @knowledge_area_lesson_plan, location: knowledge_area_lesson_plans_path
    else
      @unities = fetch_unities
      @classrooms =  fetch_classrooms
      @knowledge_areas = fetch_knowledge_area

      render :edit
    end
  end

  def destroy
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id])

    @knowledge_area_lesson_plan.destroy

    respond_with @knowledge_area_lesson_plan, location: knowledge_area_lesson_plans_path
  end

  def history
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id])

    authorize @knowledge_area_lesson_plan

    respond_with @knowledge_area_lesson_plan
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

  def fetch_unities
    Unity.by_teacher(current_teacher.id).ordered
  end

  def fetch_classrooms
    Classroom.by_unity_and_teacher(
      current_user_unity.id,
      current_teacher.id
    )
    .ordered
  end

  def fetch_knowledge_area
    KnowledgeArea.all
  end
end
