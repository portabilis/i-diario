class DisciplineLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_clasroom, only: [:new, :edit, :create, :update]
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy, :clone]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    @discipline_lesson_plans = apply_scopes(
      DisciplineLessonPlan.includes(:discipline, lesson_plan: [:classroom, :lesson_plan_attachments, :teacher])
                          .by_unity_id(current_unity.id)
                          .by_classroom_id(current_user_classroom)
                          .by_discipline_id(current_user_discipline)
                          .uniq
                          .ordered
    ).select(
      DisciplineLessonPlan.arel_table[Arel.sql('*')],
      LessonPlan.arel_table[:start_at],
      LessonPlan.arel_table[:end_at]
    )

    if author_type.present?
      @discipline_lesson_plans = @discipline_lesson_plans.by_author(author_type, current_teacher)
      params[:filter][:by_author] = author_type
    end

    authorize @discipline_lesson_plans

    @classrooms = fetch_classrooms
    @disciplines = fetch_disciplines
  end

  def show
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id]).localized

    authorize @discipline_lesson_plan

    respond_with @discipline_lesson_plan do |format|
      format.pdf do
        discipline_lesson_plan_pdf = DisciplineLessonPlanPdf.build(
          current_entity_configuration,
          @discipline_lesson_plan,
          current_teacher
        )
        send_pdf(t("routes.discipline_lesson_plan"), discipline_lesson_plan_pdf.render)
      end
    end
  end

  def new
    @discipline_lesson_plan = DisciplineLessonPlan.new.localized
    @discipline_lesson_plan.build_lesson_plan
    @discipline_lesson_plan.lesson_plan.classroom = current_user_classroom
    @discipline_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @discipline_lesson_plan.lesson_plan.teacher_id = current_teacher.id
    @discipline_lesson_plan.lesson_plan.start_at = Time.zone.today
    @discipline_lesson_plan.lesson_plan.end_at = Time.zone.today

    authorize @discipline_lesson_plan

  end

  def create
    @discipline_lesson_plan = DisciplineLessonPlan.new
    @discipline_lesson_plan.assign_attributes(resource_params)
    @discipline_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @discipline_lesson_plan.lesson_plan.content_ids = content_ids
    @discipline_lesson_plan.lesson_plan.objective_ids = objective_ids
    @discipline_lesson_plan.lesson_plan.teacher = current_teacher
    @discipline_lesson_plan.teacher_id = current_teacher_id

    authorize @discipline_lesson_plan

    if @discipline_lesson_plan.save
      respond_with @discipline_lesson_plan, location: discipline_lesson_plans_path
    else
      render :new
    end
  end

  def edit
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id]).localized

    authorize @discipline_lesson_plan
  end

  def update
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id])
    @discipline_lesson_plan.assign_attributes(resource_params)
    @discipline_lesson_plan.lesson_plan.content_ids = content_ids
    @discipline_lesson_plan.lesson_plan.objective_ids = objective_ids
    @discipline_lesson_plan.teacher_id = current_teacher_id

    authorize @discipline_lesson_plan

    if @discipline_lesson_plan.save
      respond_with @discipline_lesson_plan, location: discipline_lesson_plans_path
    else
      render :edit
    end
  end

  def destroy
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id])

    @discipline_lesson_plan.destroy

    respond_with @discipline_lesson_plan, location: discipline_lesson_plans_path
  end

  def history
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id])

    authorize @discipline_lesson_plan

    respond_with @discipline_lesson_plan
  end

  def clone
    @form = DisciplineLessonPlanClonerForm.new(
      clone_params.merge(teacher: current_teacher, entity_id: current_entity.id)
    )

    flash[:success] = t('.messages.copy_succeed') if @form.clone!
  end

  def teaching_plan_contents
    @teaching_plan_contents = DisciplineTeachingPlanContentsFetcher.new(
      current_teacher,
      current_user_classroom,
      current_user_discipline,
      params[:start_date],
      params[:end_date]
    ).fetch

    respond_with(@teaching_plan_contents)
  end

  def teaching_plan_objectives
    @teaching_plan_objectives = DisciplineTeachingPlanObjectivesFetcher.new(
      current_teacher,
      current_user_classroom,
      current_user_discipline,
      params[:start_date],
      params[:end_date]
    ).fetch

    respond_with(@teaching_plan_objectives)
  end

  private

  def content_ids
    param_content_ids = params[:discipline_lesson_plan][:lesson_plan_attributes][:content_ids] || []
    content_descriptions = params[:discipline_lesson_plan][:lesson_plan_attributes][:content_descriptions] || []

    @discipline_lesson_plan.lesson_plan.contents_created_at_position = {}

    param_content_ids.each_with_index do |content_id, index|
      @discipline_lesson_plan.lesson_plan.contents_created_at_position[content_id.to_i] = index
    end

    new_contents_ids = content_descriptions.each_with_index.map { |description, index|
      content = Content.find_or_create_by!(description: description)
      @discipline_lesson_plan.lesson_plan.contents_created_at_position[content.id] = param_content_ids.size + index

      content.id
    }

    @ordered_content_ids = param_content_ids + new_contents_ids
  end

  def objective_ids
    param_objective_ids = params[:discipline_lesson_plan][:lesson_plan_attributes][:objective_ids] || []
    objective_descriptions =
      params[:discipline_lesson_plan][:lesson_plan_attributes][:objective_descriptions] || []

    @discipline_lesson_plan.lesson_plan.objectives_created_at_position = {}

    param_objective_ids.each_with_index do |objective_id, index|
      @discipline_lesson_plan.lesson_plan.objectives_created_at_position[objective_id.to_i] = index
    end

    new_objectives_ids = objective_descriptions.each_with_index.map { |description, index|
      objective = Objective.find_or_create_by!(description: description)
      @discipline_lesson_plan.lesson_plan.objectives_created_at_position[objective.id] =
        param_objective_ids.size + index

      objective.id
    }

    @ordered_objective_ids = param_objective_ids + new_objectives_ids
  end

  def resource_params
    params.require(:discipline_lesson_plan).permit(
      :lesson_plan_id,
      :discipline_id,
      :classes,
      :thematic_unit,
      lesson_plan_attributes: [
        :id,
        :school_calendar_id,
        :unity_id,
        :classroom_id,
        :start_at,
        :end_at,
        :contents,
        :activities,
        :resources,
        :evaluation,
        :bibliography,
        :opinion,
        :teacher_id,
        :validated,
        lesson_plan_attachments_attributes: [
          :id,
          :attachment,
          :_destroy
        ]
      ]
    )
  end

  def clone_params
    params.require(:discipline_lesson_plan_cloner_form).permit(:discipline_lesson_plan_id,
                                                               discipline_lesson_plan_item_cloner_form_attributes: [
                                                                 :uuid,
                                                                 :classroom_id,
                                                                 :start_at,
                                                                 :end_at
                                                                ])
  end

  def contents
    @contents = []

    return @contents if @discipline_lesson_plan.lesson_plan.content_ids.blank?

    @contents = if @ordered_content_ids.present?
                  Content.find_and_order_by_id_sequence(@ordered_content_ids)
                else
                  @discipline_lesson_plan.lesson_plan.contents_ordered
                end

    @contents = @contents.each { |content| content.is_editable = true }.uniq
  end
  helper_method :contents

  def objectives
    @objectives = []

    return @objectives if @discipline_lesson_plan.lesson_plan.objective_ids.blank?

    @objectives = if @ordered_objective_ids.present?
                    Objective.find_and_order_by_id_sequence(@ordered_objective_ids)
                  else
                    @discipline_lesson_plan.lesson_plan.objectives_ordered
                  end

    @objectives = @objectives.each { |objective| objective.is_editable = true }.uniq
  end
  helper_method :objectives

  def fetch_unities
    Unity.by_teacher(current_teacher.id).ordered
  end

  def fetch_classrooms
    Classroom.where(id: current_user_classroom)
      .ordered
  end

  def fetch_disciplines
    Discipline.where(id: current_user_discipline)
      .ordered
  end
end
