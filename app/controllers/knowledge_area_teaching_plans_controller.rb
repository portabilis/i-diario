class KnowledgeAreaTeachingPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_year, if: :current_user_is_employee_or_administrator?
  before_action :require_current_teacher, unless: :current_user_is_employee_or_administrator?
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]
  before_action :yearly_term_type_id, only: [:show, :edit, :new]
  before_action :require_current_classroom, only: [:index, :new, :create, :edit, :update]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    @knowledge_area_teaching_plans = fetch_knowledge_area_teaching_plans

    set_options_by_user
    set_knowledge_area_by_classroom(@classrooms.map(&:id))

    unless current_user.current_role_is_admin_or_employee?
      @knowledge_area_teaching_plans = @knowledge_area_teaching_plans.by_grade(@grades.map(&:id))
    end

    if author_type.present?
      @knowledge_area_teaching_plans = @knowledge_area_teaching_plans.by_author(author_type, current_teacher)
      params[:filter][:by_author] = author_type
    end

    authorize @knowledge_area_teaching_plans
  end

  def show
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id]).localized

    authorize @knowledge_area_teaching_plan

    set_options_by_user
    @knowledge_areas = @knowledge_area_teaching_plan.knowledge_areas

    respond_with @knowledge_area_teaching_plan do |format|
      format.pdf do
        knowledge_area_teaching_plan_pdf = KnowledgeAreaTeachingPlanPdf.build(
          current_entity_configuration,
          @knowledge_area_teaching_plan
        )
        send_pdf(t('routes.knowledge_area_teaching_plans'), knowledge_area_teaching_plan_pdf.render)
      end
    end
  end

  def new
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.new.localized
    @knowledge_area_teaching_plan.build_teaching_plan(
      year: current_school_calendar.year,
      grade: current_grade,
      unity: current_unity
    )

    authorize @knowledge_area_teaching_plan

    set_options_by_user
    set_knowledge_area_by_classroom(current_user_classroom.id)
  end

  def create
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.new(resource_params).localized
    @knowledge_area_teaching_plan.teaching_plan.teacher = current_teacher
    @knowledge_area_teaching_plan.teaching_plan.content_ids = content_ids
    @knowledge_area_teaching_plan.teaching_plan.objective_ids = objective_ids
    @knowledge_area_teaching_plan.teacher_id = current_teacher_id
    @knowledge_area_teaching_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')
    @knowledge_area_teaching_plan.teaching_plan.methodology = ActionController::Base.helpers.sanitize(
      resource_params[:teaching_plan_attributes][:methodology], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @knowledge_area_teaching_plan.teaching_plan.evaluation = ActionController::Base.helpers.sanitize(
      resource_params[:teaching_plan_attributes][:evaluation], tags: ['b', 'br', 'i', 'u', 'p' ]
    )
    @knowledge_area_teaching_plan.teaching_plan.references = ActionController::Base.helpers.sanitize(
      resource_params[:teaching_plan_attributes][:references], tags: ['b', 'br', 'i', 'u', 'p' ]
    )

    authorize @knowledge_area_teaching_plan

    if @knowledge_area_teaching_plan.save
      respond_with @knowledge_area_teaching_plan, location: knowledge_area_teaching_plans_path
    else
      yearly_term_type_id
      set_options_by_user
      @knowledge_areas = @knowledge_area_teaching_plan.knowledge_areas

      render :new
    end
  end

  def edit
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id]).localized
    @knowledge_areas = @knowledge_area_teaching_plan.knowledge_areas

    set_options_by_user

    authorize @knowledge_area_teaching_plan
  end

  def update
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id]).localized
    @knowledge_area_teaching_plan.assign_attributes(resource_params.to_h)
    @knowledge_area_teaching_plan.teaching_plan.content_ids = content_ids
    @knowledge_area_teaching_plan.teaching_plan.objective_ids = objective_ids
    @knowledge_area_teaching_plan.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')
    @knowledge_area_teaching_plan.teacher_id = current_teacher_id
    @knowledge_area_teaching_plan.teaching_plan.teacher_id = current_teacher_id
    @knowledge_area_teaching_plan.teaching_plan.methodology = ActionController::Base.helpers.sanitize(
      resource_params[:teaching_plan_attributes][:methodology], tags: ['b', 'br', 'i', 'u', 'p']
    )
    @knowledge_area_teaching_plan.teaching_plan.evaluation = ActionController::Base.helpers.sanitize(
      resource_params[:teaching_plan_attributes][:evaluation], tags: ['b', 'br', 'i', 'u', 'p' ]
    )
    @knowledge_area_teaching_plan.teaching_plan.references = ActionController::Base.helpers.sanitize(
      resource_params[:teaching_plan_attributes][:references], tags: ['b', 'br', 'i', 'u', 'p' ]
    )

    authorize @knowledge_area_teaching_plan

    if @knowledge_area_teaching_plan.save
      respond_with @knowledge_area_teaching_plan, location: knowledge_area_teaching_plans_path
    else
      yearly_term_type_id
      set_options_by_user
      @knowledge_areas = @knowledge_area_teaching_plan.knowledge_areas

      render :edit
    end
  end

  def destroy
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id]).localized

    authorize @knowledge_area_teaching_plan

    @knowledge_area_teaching_plan.destroy

    respond_with @knowledge_area_teaching_plan, location: knowledge_area_teaching_plans_path
  end

  def history
    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id])

    authorize @knowledge_area_teaching_plan

    respond_with @knowledge_area_teaching_plan
  end


  def copy
    unless current_user.can_change?(:copy_knowledge_area_teaching_plan)
      flash[:error] = t('knowledge_area_teaching_plans.do.permission')
      return redirect_to :knowledge_area_teaching_plans
    end

    @knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(params[:id])
    @copy_knowledge_area_teaching_plan = CopyKnowledgeAreaTeachingPlanForm.new(
      knowledge_area_teaching_plan: @knowledge_area_teaching_plan,
      teaching_plan: @knowledge_area_teaching_plan.teaching_plan
    )

    set_options_by_user
    set_knowledge_area_by_classroom(@classrooms.map(&:id))
  end

  def do_copy
    unless current_user.can_change?(:copy_knowledge_area_teaching_plan)
      flash[:error] = t('knowledge_area_teaching_plans.do.permission')
      return redirect_to :knowledge_area_teaching_plans
    end

    form = params[:copy_knowledge_area_teaching_plan_form]

    knowledge_area_teaching_plan = KnowledgeAreaTeachingPlan.find(form[:id])
    @copy_knowledge_area_teaching_plan = CopyKnowledgeAreaTeachingPlanForm.new(
      knowledge_area_teaching_plan: knowledge_area_teaching_plan,
      teaching_plan: knowledge_area_teaching_plan.teaching_plan,
      unities_ids: form[:unities_ids],
      grades_ids: form[:grades_ids],
      year: form[:year]
    )

    unless @copy_knowledge_area_teaching_plan.valid?
      return render :copy
    end

    CopyKnowledgeAreaTeachingPlanWorker.perform_in(
      1.second,
      current_entity.id,
      current_user.id,
      form[:id],
      form[:year],
      form[:unities_ids].split(','),
      form[:grades_ids].split(',')
    )

    flash[:success] = t('knowledge_area_teaching_plans.do_copy.copying')

    redirect_to :knowledge_area_teaching_plans
  end

  private

  def content_ids
    param_content_ids = params[:knowledge_area_teaching_plan][:teaching_plan_attributes][:content_ids] || []
    content_descriptions = params[:knowledge_area_teaching_plan][:teaching_plan_attributes][:content_descriptions] || []

    @knowledge_area_teaching_plan.teaching_plan.contents_created_at_position = {}

    param_content_ids.each_with_index do |content_id, index|
      @knowledge_area_teaching_plan.teaching_plan.contents_created_at_position[content_id.to_i] = index
    end

    new_contents_ids = content_descriptions.each_with_index.map { |description, index|
      content = Content.find_or_create_by!(description: description)
      @knowledge_area_teaching_plan.teaching_plan.contents_created_at_position[content.id] =
        param_content_ids.size + index

      content.id
    }

    @ordered_content_ids = param_content_ids + new_contents_ids
  end

  def objective_ids
    param_objective_ids = params[:knowledge_area_teaching_plan][:teaching_plan_attributes][:objective_ids] || []
    objective_descriptions =
      params[:knowledge_area_teaching_plan][:teaching_plan_attributes][:objective_descriptions] || []

    @knowledge_area_teaching_plan.teaching_plan.objectives_created_at_position = {}

    param_objective_ids.each_with_index do |objective_id, index|
      @knowledge_area_teaching_plan.teaching_plan.objectives_created_at_position[objective_id.to_i] = index
    end

    new_objectives_ids = objective_descriptions.each_with_index.map { |description, index|
      objective = Objective.find_or_create_by!(description: description)
      @knowledge_area_teaching_plan.teaching_plan.objectives_created_at_position[objective.id] =
        param_objective_ids.size + index

      objective.id
    }

    @ordered_objective_ids = param_objective_ids + new_objectives_ids
  end

  def resource_params
    params.require(:knowledge_area_teaching_plan).permit(
      :knowledge_area_ids,
      :experience_fields,
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

    return @contents if @knowledge_area_teaching_plan.teaching_plan.content_ids.blank?

    @contents = if @ordered_content_ids.present?
                  Content.find_and_order_by_id_sequence(@ordered_content_ids)
                else
                  @knowledge_area_teaching_plan.teaching_plan.contents_ordered
                end

    @contents = @contents.each { |content| content.is_editable = true }.uniq
  end
  helper_method :contents

  def objectives
    @objectives = []

    return @objectives if @knowledge_area_teaching_plan.teaching_plan.objective_ids.blank?

    @objectives = if @ordered_objective_ids.present?
                    Objective.find_and_order_by_id_sequence(@ordered_objective_ids)
                  else
                    @knowledge_area_teaching_plan.teaching_plan.objectives_ordered
                  end

    @objectives = @objectives.each { |objective| objective.is_editable = true }.uniq
  end
  helper_method :objectives

  def set_options_by_user
    return fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    @grades ||= current_user_classroom.classrooms_grades.map(&:grade).uniq
    @classrooms ||= [current_user_classroom]
  end

  def set_knowledge_area_by_classroom(classroom_id)
    @knowledge_areas = KnowledgeArea.by_teacher(current_teacher)
                                    .by_classroom_id(classroom_id)
                                    .ordered
  end

  def yearly_term_type_id
    @yearly_term_type_id ||= SchoolTermType.find_by(description: 'Anual').id
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(
      current_teacher.id,
      current_unity,
      current_school_year
    )
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
    @grades ||= @fetch_linked_by_teacher[:classroom_grades].map(&:grade).uniq
  end

  def fetch_knowledge_area_teaching_plans
    apply_scopes(
      KnowledgeAreaTeachingPlan.includes(:knowledge_areas, teaching_plan:
                                  [:unity, :grade, :teaching_plan_attachments, :teacher,
                                   :school_term_type, :school_term_type_step])
                                .by_unity(current_unity)
                                .by_year(current_school_year)
                                .order_by_grades
                                .order_by_school_term_type_step
    )
  end

  def current_grade
    current_user_grade = ClassroomsGrade.by_classroom_id(current_user_classroom.id).first.grade
  end
end
