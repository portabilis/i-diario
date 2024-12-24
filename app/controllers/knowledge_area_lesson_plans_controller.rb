class KnowledgeAreaLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom, only: [:index, :new, :edit, :create, :update]
  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy, :clone]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    if current_user.current_role_is_admin_or_employee?
      fetch_classrooms
    else
      fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?
    end

    @knowledge_area_lesson_plans = fetch_knowledge_area_by_user

    if author_type.present?
      @knowledge_area_lesson_plans = @knowledge_area_lesson_plans.by_author(author_type, current_teacher)
      params[:filter][:by_author] = author_type
    end

    authorize @knowledge_area_lesson_plans

    @knowledge_areas = fetch_knowledge_area
  end

  def show
    fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id]).localized

    authorize @knowledge_area_lesson_plan
    @knowledge_areas = fetch_knowledge_area

    respond_with @knowledge_area_lesson_plan
  end

  def print
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id]).localized

    knowledge_area_lesson_plan_pdf = KnowledgeAreaLessonPlanPdf.build(
      current_entity_configuration,
      @knowledge_area_lesson_plan,
      current_teacher
    )
    send_pdf(t('routes.knowledge_area_lesson_plans'), knowledge_area_lesson_plan_pdf.render)
  end

  def new
    if current_user.current_role_is_admin_or_employee?
      fetch_classrooms
    else
      fetch_linked_by_teacher
    end

    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.new.localized
    @knowledge_area_lesson_plan.build_lesson_plan
    @knowledge_area_lesson_plan.lesson_plan.classroom = current_user_classroom
    @knowledge_area_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @knowledge_area_lesson_plan.lesson_plan.teacher_id = current_teacher.id
    @knowledge_area_lesson_plan.lesson_plan.start_at = Time.zone.today
    @knowledge_area_lesson_plan.lesson_plan.end_at = Time.zone.today

    authorize @knowledge_area_lesson_plan

    fetch_unities
    @knowledge_areas = fetch_knowledge_area
  end

  def create
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.new
    @knowledge_area_lesson_plan.assign_attributes(resource_params)
    @knowledge_area_lesson_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')
    @knowledge_area_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @knowledge_area_lesson_plan.lesson_plan.content_ids = content_ids
    @knowledge_area_lesson_plan.lesson_plan.objective_ids = objective_ids
    @knowledge_area_lesson_plan.lesson_plan.teacher = current_teacher
    @knowledge_area_lesson_plan.teacher_id = current_teacher_id
    @knowledge_area_lesson_plan.lesson_plan.activities = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:activities], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @knowledge_area_lesson_plan.lesson_plan.resources = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:resources], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @knowledge_area_lesson_plan.lesson_plan.evaluation = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:evaluation], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @knowledge_area_lesson_plan.lesson_plan.bibliography = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:bibliography], tags: ['b', 'br', 'i', 'u', 'p']
    )

    authorize @knowledge_area_lesson_plan

    if @knowledge_area_lesson_plan.save
      respond_with @knowledge_area_lesson_plan, location: knowledge_area_lesson_plans_path
    else
      fetch_unities
      fetch_classrooms
      @knowledge_areas = fetch_knowledge_area

      render :new
    end
  end

  def edit
    fetch_linked_by_teacher

    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id]).localized

    authorize @knowledge_area_lesson_plan

    fetch_unities
    fetch_classrooms if current_user.current_role_is_admin_or_employee?
    @knowledge_areas = fetch_knowledge_area
  end

  def update
    @knowledge_area_lesson_plan = KnowledgeAreaLessonPlan.find(params[:id])
    @knowledge_area_lesson_plan.assign_attributes(resource_params)
    @knowledge_area_lesson_plan.lesson_plan.content_ids = content_ids
    @knowledge_area_lesson_plan.lesson_plan.objective_ids = objective_ids
    @knowledge_area_lesson_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')
    @knowledge_area_lesson_plan.teacher_id = current_teacher_id
    @knowledge_area_lesson_plan.lesson_plan.activities = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:activities], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @knowledge_area_lesson_plan.lesson_plan.resources = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:resources], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @knowledge_area_lesson_plan.lesson_plan.evaluation = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:evaluation], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @knowledge_area_lesson_plan.lesson_plan.bibliography = ActionController::Base.helpers.sanitize(
      resource_params[:lesson_plan_attributes][:bibliography], tags: ['b', 'br', 'i', 'u', 'p']
    )

    authorize @knowledge_area_lesson_plan

    if @knowledge_area_lesson_plan.save
      respond_with @knowledge_area_lesson_plan, location: knowledge_area_lesson_plans_path
    else
      fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

      fetch_unities
      fetch_classrooms if current_user.current_role_is_admin_or_employee?
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
    @form = KnowledgeAreaLessonPlanClonerForm.new(
      clone_params.merge(teacher: current_teacher, entity_id: current_entity.id)
    )

    flash[:success] = t('.messages.copy_succeed') if @form.clone!
  end

  def valid_params
    return if params[:classroom_id].blank?

    @classroom = Classroom.find_by(id: params[:classroom_id])
  end

  def teaching_plan_contents
    valid_params

    @teaching_plan_contents = KnowledgeAreaTeachingPlanContentsFetcher.new(
      current_teacher,
      @classroom,
      params[:knowledge_area_ids],
      params[:start_date],
      params[:end_date]
    ).fetch

    respond_with(@teaching_plan_contents)
  end

  def teaching_plan_objectives
    valid_params

    @teaching_plan_objectives = KnowledgeAreaTeachingPlanObjectivesFetcher.new(
      current_teacher,
      @classroom,
      params[:knowledge_area_ids],
      params[:start_date],
      params[:end_date]
    ).fetch

    respond_with(@teaching_plan_objectives)
  end

  private

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = @fetch_linked_by_teacher[:classrooms]
    @disciplines = @fetch_linked_by_teacher[:disciplines]
  end

  def content_ids
    param_content_ids = params[:knowledge_area_lesson_plan][:lesson_plan_attributes][:content_ids] || []
    content_descriptions = params[:knowledge_area_lesson_plan][:lesson_plan_attributes][:content_descriptions] || []

    @knowledge_area_lesson_plan.lesson_plan.contents_created_at_position = {}

    param_content_ids.each_with_index do |content_id, index|
      @knowledge_area_lesson_plan.lesson_plan.contents_created_at_position[content_id.to_i] = index
    end

    new_contents_ids = content_descriptions.each_with_index.map { |description, index|
      content = Content.find_or_create_by!(description: description)
      @knowledge_area_lesson_plan.lesson_plan.contents_created_at_position[content.id] =
        param_content_ids.size + index

      content.id
    }

    @ordered_content_ids = param_content_ids + new_contents_ids
  end

  def objective_ids
    param_objective_ids = params[:knowledge_area_lesson_plan][:lesson_plan_attributes][:objective_ids] || []
    objective_descriptions =
      params[:knowledge_area_lesson_plan][:lesson_plan_attributes][:objective_descriptions] || []

    @knowledge_area_lesson_plan.lesson_plan.objectives_created_at_position = {}

    param_objective_ids.each_with_index do |objective_id, index|
      @knowledge_area_lesson_plan.lesson_plan.objectives_created_at_position[objective_id.to_i] = index
    end

    new_objectives_ids = objective_descriptions.each_with_index.map { |description, index|
      objective = Objective.find_or_create_by!(description: description)
      @knowledge_area_lesson_plan.lesson_plan.objectives_created_at_position[objective.id] =
        param_objective_ids.size + index

      objective.id
    }

    @ordered_objective_ids = param_objective_ids + new_objectives_ids
  end

  def resource_params
    params.require(:knowledge_area_lesson_plan).permit(
      :lesson_plan_id,
      :knowledge_area_ids,
      :experience_fields,
      lesson_plan_attributes: [
        :id,
        :school_calendar_id,
        :unity_id,
        :classroom_id,
        :start_at,
        :end_at,
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
    params.require(:knowledge_area_lesson_plan_cloner_form).permit(:knowledge_area_lesson_plan_id,
                                                                   knowledge_area_lesson_plan_item_cloner_form_attributes: [
                                                                     :uuid,
                                                                     :classroom_id,
                                                                     :start_at,
                                                                     :end_at
                                                                   ])
  end

  def contents
    @contents = []

    return @contents if @knowledge_area_lesson_plan.lesson_plan.content_ids.blank?

    @contents = if @ordered_content_ids.present?
                  Content.find_and_order_by_id_sequence(@ordered_content_ids)
                else
                  @knowledge_area_lesson_plan.lesson_plan.contents_ordered
                end

    @contents = @contents.each { |content| content.is_editable = true }.uniq
  end
  helper_method :contents

  def objectives
    @objectives = []

    return @objectives if @knowledge_area_lesson_plan.lesson_plan.objective_ids.blank?

    @objectives = if @ordered_objective_ids.present?
                    Objective.find_and_order_by_id_sequence(@ordered_objective_ids)
                  else
                    @knowledge_area_lesson_plan.lesson_plan.objectives_ordered
                  end

    @objectives = @objectives.each { |objective| objective.is_editable = true }.uniq
  end
  helper_method :objectives

  def fetch_unities
    @unities ||= Unity.by_teacher(current_teacher.id).ordered
  end

  def fetch_classrooms
    @classrooms ||= [current_user_classroom]
  end

  def fetch_knowledge_area
    knowledge_areas = KnowledgeArea.by_teacher(current_teacher).ordered

    knowledge_areas = if current_user.current_role_is_admin_or_employee?
                        knowledge_areas.by_classroom_id(current_user_classroom.id)
                      else
                        knowledge_areas.by_classroom_id(@classrooms.map(&:id))
                      end
    knowledge_areas
  end

  def fetch_knowledge_area_by_user
    apply_scopes(KnowledgeAreaLessonPlan
      .includes(:knowledge_areas, lesson_plan: [:classroom, :lesson_plan_attachments, :teacher])
      .by_classroom_id(@classrooms.map(&:id))
      .order_by_classrooms
      .ordered).select(
        KnowledgeAreaLessonPlan.arel_table[Arel.sql('*')],
        LessonPlan.arel_table[:start_at],
        LessonPlan.arel_table[:end_at]
      )
  end
end
