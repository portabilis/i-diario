class DisciplineLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom, only: [:index, :new, :edit, :create, :update]
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy, :clone]
  before_action :require_allows_copy_experience_fields_in_lesson_plans, only: [:new, :edit]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    set_options_by_user

    if author_type.present?
      @discipline_lesson_plans = @discipline_lesson_plans.by_author(author_type, current_teacher)
      params[:filter][:by_author] = author_type
    end

    authorize @discipline_lesson_plans
  end

  def show
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id]).localized

    set_options_by_user

    authorize @discipline_lesson_plan

    respond_with @discipline_lesson_plan
  end

  def print
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id]).localized

    discipline_lesson_plan_pdf = DisciplineLessonPlanPdf.build(
      current_entity_configuration,
      @discipline_lesson_plan,
      current_teacher
    )
    send_pdf(t("routes.discipline_lesson_plan"), discipline_lesson_plan_pdf.render)
  end

  def new
    @discipline_lesson_plan = DisciplineLessonPlan.new.localized
    @discipline_lesson_plan.build_lesson_plan
    @discipline_lesson_plan.discipline = current_user_discipline
    @discipline_lesson_plan.lesson_plan.classroom = current_user_classroom
    @discipline_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @discipline_lesson_plan.lesson_plan.teacher_id = current_teacher.id
    @discipline_lesson_plan.lesson_plan.start_at = Time.zone.today
    @discipline_lesson_plan.lesson_plan.end_at = Time.zone.today

    set_options_by_user
    fetch_disciplines_by_classroom

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
    @discipline_lesson_plan.lesson_plan.activities = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:activities], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @discipline_lesson_plan.lesson_plan.resources = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:resources], tags: ['b','br', 'i', 'u', 'p']
    )
    @discipline_lesson_plan.lesson_plan.evaluation = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:evaluation], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @discipline_lesson_plan.lesson_plan.bibliography = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:bibliography], tags: ['b', 'br', 'i', 'u', 'p']
    )

    authorize @discipline_lesson_plan

    if @discipline_lesson_plan.save
      respond_with @discipline_lesson_plan, location: discipline_lesson_plans_path
    else
      fetch_disciplines_by_classroom

      render :new
    end
  end

  def edit
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id]).localized

    set_options_by_user
    fetch_disciplines_by_classroom

    authorize @discipline_lesson_plan
  end

  def update
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id])
    @discipline_lesson_plan.assign_attributes(resource_params)
    @discipline_lesson_plan.lesson_plan.content_ids = content_ids
    @discipline_lesson_plan.lesson_plan.objective_ids = objective_ids
    @discipline_lesson_plan.teacher_id = current_teacher_id
    @discipline_lesson_plan.lesson_plan.activities = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:activities], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @discipline_lesson_plan.lesson_plan.resources = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:resources], tags: ['b','br', 'i', 'u', 'p']
    )
    @discipline_lesson_plan.lesson_plan.evaluation = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:evaluation], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @discipline_lesson_plan.lesson_plan.bibliography = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:bibliography], tags: ['b', 'br', 'i', 'u', 'p']
    )

    authorize @discipline_lesson_plan

    if @discipline_lesson_plan.save
      respond_with @discipline_lesson_plan, location: discipline_lesson_plans_path
    else
      fetch_disciplines_by_classroom

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

  def valid_params
    return if params[:classroom_id].blank? || params[:discipline_id].blank?

    @classroom = Classroom.find_by(id: params[:classroom_id])
    @discipline_id = params[:discipline_id]
  end

  def teaching_plan_contents
    valid_params

    @teaching_plan_contents = DisciplineTeachingPlanContentsFetcher.new(
      current_teacher,
      @classroom,
      @discipline_id,
      params[:start_date],
      params[:end_date]
    ).fetch

    respond_with(@teaching_plan_contents)
  end

  def teaching_plan_objectives
    valid_params

    @teaching_plan_objectives = DisciplineTeachingPlanObjectivesFetcher.new(
      current_teacher,
      @classroom,
      @discipline_id,
      params[:start_date],
      params[:end_date]
    ).fetch

    respond_with(@teaching_plan_objectives)
  end

  private

  def fetch_discipline_lesson_plan(disciplines)
    apply_scopes(DisciplineLessonPlan
      .includes(:discipline, lesson_plan: [:classroom, :lesson_plan_attachments, :teacher])
      .by_unity_id(current_unity.id)
      .by_classroom_id(@classrooms.map(&:id))
      .by_discipline_id(disciplines.map(&:id))
      .order_by_classrooms
      .ordered).select(
        DisciplineLessonPlan.arel_table[Arel.sql('*')],
        LessonPlan.arel_table[:start_at],
        LessonPlan.arel_table[:end_at]
      )
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = @fetch_linked_by_teacher[:classrooms]
    @disciplines = @fetch_linked_by_teacher[:disciplines]
  end

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
    @classrooms ||= [current_user_classroom]
  end

  def fetch_disciplines
    @disciplines ||= [current_user_discipline]
  end

  def set_options_by_user
    if current_user.current_role_is_admin_or_employee?
      fetch_classrooms
      fetch_disciplines

      discipline = if current_user_discipline&.grouper?
                     Discipline.where(knowledge_area_id: @disciplines.map(&:knowledge_area_id)).all
                   else
                     Discipline.where(id: @disciplines.map(&:id))
                   end

      @discipline_lesson_plans = fetch_discipline_lesson_plan(discipline)
    else
      fetch_linked_by_teacher
      @discipline_lesson_plans = fetch_discipline_lesson_plan(@disciplines)
    end
  end

  def require_allows_copy_experience_fields_in_lesson_plans
    @allows_copy_experience_fields_in_lesson_plans ||= GeneralConfiguration.current.allows_copy_experience_fields_in_lesson_plans
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    fetch_linked_by_teacher
    classroom = @discipline_lesson_plan.lesson_plan.classroom
    @disciplines = @disciplines.by_classroom(classroom).not_descriptor
  end
end
