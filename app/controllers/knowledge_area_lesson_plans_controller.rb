class KnowledgeAreaLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher

  def index
    author_type = (params[:filter] || []).delete(:by_author)

    @knowledge_area_lesson_plans = apply_scopes(
      KnowledgeAreaLessonPlan.includes(:knowledge_areas, lesson_plan: [:classroom])
                             .by_classroom_id(current_user_classroom)
                             .uniq
                             .ordered
    ).select(
      KnowledgeAreaLessonPlan.arel_table[Arel.sql('*')],
      LessonPlan.arel_table[:start_at],
      LessonPlan.arel_table[:end_at]
    )

    if author_type.present?
      @knowledge_area_lesson_plans = @knowledge_area_lesson_plans.by_author(author_type, current_teacher)
    end

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
          @knowledge_area_lesson_plan,
          current_teacher
        )
        send_pdf(t("routes.knowledge_area_lesson_plans"), knowledge_area_lesson_plan_pdf.render)
      end
    end
  end

  def new
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.new.localized
    @knowledge_area_lesson_plan.build_lesson_plan
    @knowledge_area_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @knowledge_area_lesson_plan.lesson_plan.teacher_id = current_teacher.id
    @knowledge_area_lesson_plan.lesson_plan.start_at = Time.zone.today
    @knowledge_area_lesson_plan.lesson_plan.end_at = Time.zone.today

    authorize @knowledge_area_lesson_plan

    @unities = fetch_unities
    @classrooms =  fetch_classrooms
    @knowledge_areas = fetch_knowledge_area
  end

  def create
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.new
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
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id])
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

  def clone
    @form = KnowledgeAreaLessonPlanClonerForm.new(clone_params)
    if @form.clone!
      flash[:success] = "Plano de aula por área de conhecimento copiado com sucesso!"
    end
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
        :start_at,
        :end_at,
        :contents,
        :activities,
        :objectives,
        :resources,
        :evaluation,
        :bibliography,
        :opinion,
        :teacher_id,
        contents_attributes: [
          :id,
          :description,
          :_destroy
        ],
        lesson_plan_attachments_attributes: [
          :id,
          :attachment,
          :_destroy
        ]
      ]
    )
  end

  def clone_params
    params.require(:knowledge_area_lesson_plan_cloner_form).permit(:knowledge_area_lesson_plan_id,
                                                                   knowledge_area_lesson_plan_item_cloner_form_attributes: [
                                                                     :uuid,
                                                                     :classroom_id,
                                                                     :start_at,
                                                                     :end_at
                                                                    ])
  end

  def contents
    Content.ordered
  end
  helper_method :contents

  def fetch_unities
    Unity.by_teacher(current_teacher.id).ordered
  end

  def fetch_classrooms
    Classroom.where(id: current_user_classroom)
    .ordered
  end

  def fetch_knowledge_area
    KnowledgeArea.all
  end
end
