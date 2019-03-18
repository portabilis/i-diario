class DisciplineTeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher, unless: :current_user_is_employee_or_administrator?

  def index
    author_type = (params[:filter] || []).delete(:by_author)

    @discipline_teaching_plans = apply_scopes(
      DisciplineTeachingPlan.includes(:discipline, teaching_plan: [:unity, :grade])
                            .by_unity(current_user_unity)
                            .by_year(current_user_school_year)
    )

    unless current_user_is_employee_or_administrator?
      @discipline_teaching_plans = @discipline_teaching_plans.by_grade(current_user_classroom.try(:grade))
                                                             .by_discipline(current_user_discipline)
    end

    if author_type.present?
      @discipline_teaching_plans = @discipline_teaching_plans.by_author(author_type, current_teacher)
    end

    authorize @discipline_teaching_plans

    fetch_grades
    fetch_disciplines
  end

  def show
    @discipline_teaching_plan = DisciplineTeachingPlan.find(params[:id])
      .localized

    authorize @discipline_teaching_plan

    fetch_collections

    respond_with @discipline_teaching_plans do |format|
      format.pdf do
        discipline_teaching_plan_pdf = DisciplineTeachingPlanPdf.build(
          current_entity_configuration,
          @discipline_teaching_plan
        )
        send_pdf(t("routes.discipline_teaching_plans"), discipline_teaching_plan_pdf.render)
      end
    end
  end

  def new
    @discipline_teaching_plan = DisciplineTeachingPlan.new.localized
    @discipline_teaching_plan.build_teaching_plan(
      year: current_school_calendar.year,
      unity: current_user_unity
    )

    authorize @discipline_teaching_plan

    fetch_collections
  end

  def create
    @discipline_teaching_plan = DisciplineTeachingPlan.new(resource_params)
      .localized

    authorize @discipline_teaching_plan

    @discipline_teaching_plan.teaching_plan.teacher_id = current_teacher.id unless current_user_is_employee_or_administrator?

    if @discipline_teaching_plan.save
      respond_with @discipline_teaching_plan, location: discipline_teaching_plans_path
    else
      fetch_collections

      render :new
    end
  end

  def edit
    @discipline_teaching_plan = DisciplineTeachingPlan.find(params[:id])
      .localized

    authorize @discipline_teaching_plan

    fetch_collections
  end

  def update
    @discipline_teaching_plan = DisciplineTeachingPlan.find(params[:id])
      .localized
    @discipline_teaching_plan.assign_attributes(resource_params)

    authorize @discipline_teaching_plan

    if @discipline_teaching_plan.save
      respond_with @discipline_teaching_plan, location: discipline_teaching_plans_path
    else
      fetch_collections

      render :edit
    end
  end

  def destroy
    @discipline_teaching_plan = DisciplineTeachingPlan.find(params[:id])
      .localized

    authorize @discipline_teaching_plan

    @discipline_teaching_plan.destroy

    respond_with @discipline_teaching_plan, location: discipline_teaching_plans_path
  end

  def history
    @discipline_teaching_plan = DisciplineTeachingPlan.find(params[:id])

    authorize @discipline_teaching_plan

    respond_with @discipline_teaching_plan
  end

  private

  def resource_params
    params.require(:discipline_teaching_plan).permit(
      :discipline_id,
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

  def contents
    Content.ordered
  end
  helper_method :contents

  def fetch_collections
    fetch_unities
    fetch_grades
    fetch_disciplines
  end

  def fetch_unities
    @unities = Unity.by_teacher(current_teacher).ordered
  end

  def fetch_grades
    @grades = Grade.by_unity(current_user_unity)
      .by_year(current_school_calendar.year)
      .ordered

    @grades = @grades.by_teacher(current_teacher) unless current_user_is_employee_or_administrator?
  end

  def fetch_disciplines
    if current_user_is_employee_or_administrator?
      @disciplines = Discipline.by_unity_id(current_user_unity)
    else
      @disciplines = Discipline.where(id: current_user_discipline)
      .ordered
    end

    if @discipline_teaching_plan.present?
      @disciplines = @disciplines.by_grade(
          @discipline_teaching_plan.teaching_plan.grade
        )
        .ordered
    end

    @disciplines
  end
end
