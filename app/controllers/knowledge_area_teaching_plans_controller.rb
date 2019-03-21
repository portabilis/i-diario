class KnowledgeAreaTeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher, unless: :current_user_is_employee_or_administrator?

  def index
    author_type = (params[:filter] || []).delete(:by_author)

    @knowledge_area_teaching_plans = apply_scopes(
      KnowledgeAreaTeachingPlan.includes(:knowledge_areas, teaching_plan: [:unity, :grade])
                               .by_unity(current_user_unity)
                               .by_year(current_user_school_year)
    )

    unless current_user_is_employee_or_administrator?
      @knowledge_area_teaching_plans =
        @knowledge_area_teaching_plans.by_grade(current_user_classroom.try(:grade_id))
    end

    if author_type.present?
      @discipline_teaching_plans = @discipline_teaching_plans.by_author(author_type, current_teacher)
    end

    authorize @knowledge_area_teaching_plans

    fetch_grades
    fetch_knowledge_areas
  end

  def show
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id])
      .localized

    authorize @knowledge_area_teaching_plan

    fetch_collections

    respond_with @knowledge_area_teaching_plan do |format|
      format.pdf do
        knowledge_area_teaching_plan_pdf = KnowledgeAreaTeachingPlanPdf.build(
          current_entity_configuration,
          @knowledge_area_teaching_plan
        )
        send_pdf(t("routes.knowledge_area_teaching_plans"), knowledge_area_teaching_plan_pdf.render)
      end
    end
  end

  def new
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.new.localized
    @knowledge_area_teaching_plan.build_teaching_plan(
      year: current_school_calendar.year,
      unity: current_user_unity
    )

    authorize @knowledge_area_teaching_plan

    fetch_collections
  end

  def create
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.new(resource_params)
      .localized

    authorize @knowledge_area_teaching_plan

    @knowledge_area_teaching_plan.teaching_plan.teacher_id = current_teacher.id unless current_user_is_employee_or_administrator?
    @knowledge_area_teaching_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')

    if @knowledge_area_teaching_plan.save
      respond_with @knowledge_area_teaching_plan, location: knowledge_area_teaching_plans_path
    else
      fetch_collections

      render :new
    end
  end

  def edit
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id])
      .localized

    authorize @knowledge_area_teaching_plan

    fetch_collections
  end

  def update
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id])
      .localized
    @knowledge_area_teaching_plan.assign_attributes(resource_params)
    @knowledge_area_teaching_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')

    authorize @knowledge_area_teaching_plan

    if @knowledge_area_teaching_plan.save
      respond_with @knowledge_area_teaching_plan, location: knowledge_area_teaching_plans_path
    else
      fetch_collections

      render :edit
    end
  end

  def destroy
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id])
      .localized

    authorize @knowledge_area_teaching_plan

    @knowledge_area_teaching_plan.destroy

    respond_with @knowledge_area_teaching_plan, location: knowledge_area_teaching_plans_path
  end

  def history
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id])

    authorize @knowledge_area_teaching_plan

    respond_with @knowledge_area_teaching_plan
  end

  private

  def resource_params
    params.require(:knowledge_area_teaching_plan).permit(
      :knowledge_area_ids,
      teaching_plan_attributes: [
        :id,
        :year,
        :unity_id,
        :grade_id,
        :school_term_type,
        :school_term,
        :objectives,
        :content,
        :methodology,
        :evaluation,
        :references,
        :teacher_id,
        contents_attributes: [
          :id,
          :description,
          :_destroy
        ],
        teaching_plan_attachments_attributes: [
          :id,
          :attachment,
          :_destroy
        ]
      ]
    )
  end

  def fetch_collections
    fetch_knowledge_areas
  end

  def contents
    Content.ordered
  end
  helper_method :contents

  def fetch_unities
    @unities = Unity.by_teacher(current_teacher).ordered
  end

  def fetch_grades
    @grades = Grade.by_unity(current_user_unity)
      .by_year(current_school_calendar.year)
      .ordered
    @grades = @grades.where(id: current_user_classroom.try(:grade_id))
                     .ordered unless current_user_is_employee_or_administrator?
  end

  def fetch_knowledge_areas
    @knowledge_areas = KnowledgeArea.ordered
  end
end
