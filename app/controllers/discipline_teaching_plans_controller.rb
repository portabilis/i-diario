class DisciplineTeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

   
  before_action :require_current_teacher

  def index
    @discipline_teaching_plans = apply_scopes(DisciplineTeachingPlan)
      .includes(:discipline, teaching_plan: [:unity, :grade])
      .by_unity(current_user_unity)
      .by_grade(current_user_classroom.try(:grade))
      .by_discipline(current_user_discipline)
      .by_teacher_id(current_teacher.id)

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

        send_data(
          discipline_teaching_plan_pdf.render,
          filename: 'planos-de-ensino-por-disciplina.pdf',
          type: 'application/pdf',
          disposition: 'inline'
        )
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

    @discipline_teaching_plan.teaching_plan.teacher_id = current_teacher.id

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
      .by_teacher(current_teacher)
      .by_year(current_school_calendar.year)
      .ordered
  end

  def fetch_disciplines
    @disciplines = Discipline.where(id: current_user_discipline)
      .ordered

    if @discipline_teaching_plan.present?
      @disciplines = @disciplines.by_grade(
          @discipline_teaching_plan.teaching_plan.grade
        )
        .ordered
    end

    @disciplines
  end
end
