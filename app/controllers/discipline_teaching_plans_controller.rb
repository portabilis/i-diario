class DisciplineTeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher, unless: :current_user_is_employee_or_administrator?
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]
  before_action :yearly_term_type_id, only: [:show, :edit, :new]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    @discipline_teaching_plans = apply_scopes(
      DisciplineTeachingPlan.includes(:discipline,
                                      teaching_plan: [:unity, :grade, :teaching_plan_attachments, :teacher])
                            .by_unity(current_unity)
                            .by_year(current_school_year)
    )

    unless current_user_is_employee_or_administrator?
      @discipline_teaching_plans = @discipline_teaching_plans.by_grade(current_user_classroom.try(:grade))
                                                             .by_discipline(current_user_discipline)
    end

    if author_type.present?
      @discipline_teaching_plans = @discipline_teaching_plans.by_author(author_type, current_teacher)
      params[:filter][:by_author] = author_type
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
      unity: current_unity
    )

    authorize @discipline_teaching_plan

    fetch_collections
  end

  def create
    @discipline_teaching_plan = DisciplineTeachingPlan.new(resource_params).localized
    @discipline_teaching_plan.teaching_plan.teacher = current_teacher
    @discipline_teaching_plan.teaching_plan.content_ids = content_ids
    @discipline_teaching_plan.teaching_plan.objective_ids = objective_ids
    @discipline_teaching_plan.teacher_id = current_teacher_id

    authorize @discipline_teaching_plan

    if @discipline_teaching_plan.save
      respond_with @discipline_teaching_plan, location: discipline_teaching_plans_path
    else
      yearly_term_type_id
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
    @discipline_teaching_plan = DisciplineTeachingPlan.find(params[:id]).localized
    @discipline_teaching_plan.assign_attributes(resource_params)
    @discipline_teaching_plan.teaching_plan.content_ids = content_ids
    @discipline_teaching_plan.teaching_plan.objective_ids = objective_ids
    @discipline_teaching_plan.teacher_id = current_teacher_id
    @discipline_teaching_plan.current_user = current_user

    authorize @discipline_teaching_plan

    if @discipline_teaching_plan.save
      respond_with @discipline_teaching_plan, location: discipline_teaching_plans_path
    else
      yearly_term_type_id
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

  def content_ids
    param_content_ids = params[:discipline_teaching_plan][:teaching_plan_attributes][:content_ids] || []
    content_descriptions = params[:discipline_teaching_plan][:teaching_plan_attributes][:content_descriptions] || []

    @discipline_teaching_plan.teaching_plan.contents_created_at_position = {}

    param_content_ids.each_with_index do |content_id, index|
      @discipline_teaching_plan.teaching_plan.contents_created_at_position[content_id.to_i] = index
    end

    new_contents_ids = content_descriptions.each_with_index.map { |description, index|
      content = Content.find_or_create_by!(description: description)
      @discipline_teaching_plan.teaching_plan.contents_created_at_position[content.id] =
        param_content_ids.size + index

      content.id
    }

    @ordered_content_ids = param_content_ids + new_contents_ids
  end

  def objective_ids
    param_objective_ids = params[:discipline_teaching_plan][:teaching_plan_attributes][:objective_ids] || []
    objective_descriptions =
      params[:discipline_teaching_plan][:teaching_plan_attributes][:objective_descriptions] || []

    @discipline_teaching_plan.teaching_plan.objectives_created_at_position = {}

    param_objective_ids.each_with_index do |objective_id, index|
      @discipline_teaching_plan.teaching_plan.objectives_created_at_position[objective_id.to_i] = index
    end

    new_objectives_ids = objective_descriptions.each_with_index.map { |description, index|
      objective = Objective.find_or_create_by!(description: description)
      @discipline_teaching_plan.teaching_plan.objectives_created_at_position[objective.id] =
        param_objective_ids.size + index

      objective.id
    }

    @ordered_objective_ids = param_objective_ids + new_objectives_ids
  end

  def resource_params
    params.require(:discipline_teaching_plan).permit(
      :discipline_id,
      :thematic_unit,
      teaching_plan_attributes: [
        :id,
        :year,
        :unity_id,
        :grade_id,
        :school_term_type_id,
        :school_term_type_step_id,
        :content,
        :methodology,
        :evaluation,
        :references,
        :teacher_id,
        :opinion,
        :validated,
        teaching_plan_attachments_attributes: [
          :id,
          :attachment,
          :_destroy
        ]
      ]
    )
  end

  def contents
    @contents = []

    return @contents if @discipline_teaching_plan.teaching_plan.content_ids.blank?

    @contents = if @ordered_content_ids.present?
                  Content.find_and_order_by_id_sequence(@ordered_content_ids)
                else
                  @discipline_teaching_plan.teaching_plan.contents_ordered
                end

    @contents = @contents.each { |content| content.is_editable = true }.uniq
  end
  helper_method :contents

  def objectives
    @objectives = []

    return @objectives if @discipline_teaching_plan.teaching_plan.objective_ids.blank?

    @objectives = if @ordered_objective_ids.present?
                    Objective.find_and_order_by_id_sequence(@ordered_objective_ids)
                  else
                    @discipline_teaching_plan.teaching_plan.objectives_ordered
                  end

    @objectives = @objectives.each { |objective| objective.is_editable = true }.uniq
  end
  helper_method :objectives

  def fetch_collections
    fetch_unities
    fetch_grades
    fetch_disciplines
  end

  def fetch_unities
    @unities = Unity.by_teacher(current_teacher).ordered
  end

  def fetch_grades
    @grades = Grade.by_unity(current_unity)
      .by_year(current_school_calendar.year)
      .ordered

    @grades = @grades.by_teacher(current_teacher) unless current_user_is_employee_or_administrator?
  end

  def fetch_disciplines
    if current_user_is_employee_or_administrator?
      @disciplines = Discipline.by_unity_id(current_unity)
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

  def yearly_term_type_id
    @yearly_term_type_id ||= SchoolTermType.find_by(description: 'Anual').id
  end
end
