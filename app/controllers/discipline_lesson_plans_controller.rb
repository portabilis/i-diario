class DisciplineLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_clasroom, only: [:new, :edit, :create, :update]
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy, :clone]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    @discipline_lesson_plans = apply_scopes(
      DisciplineLessonPlan.includes(:discipline, lesson_plan: [:classroom])
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

      format.html do
        redirect_to discipline_lesson_plans_path
      end
    end
  end

  def new
    @discipline_lesson_plan = DisciplineLessonPlan.new.localized
    @discipline_lesson_plan.build_lesson_plan
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
    @form = DisciplineLessonPlanClonerForm.new(clone_params.merge(teacher: current_teacher))
    if @form.clone!
      flash[:success] = "Plano de aula por disciplina copiado com sucesso!"
    end
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
    new_contents_ids = content_descriptions.map{|v| Content.find_or_create_by!(description: v).id }
    param_content_ids + new_contents_ids
  end

  def objective_ids
    param_objective_ids = params[:discipline_lesson_plan][:lesson_plan_attributes][:objective_ids] || []
    objective_descriptions =
      params[:discipline_lesson_plan][:lesson_plan_attributes][:objective_descriptions] || []
    new_objectives_ids = objective_descriptions.map { |value| Objective.find_or_create_by!(description: value).id }
    param_objective_ids + new_objectives_ids
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

    if params[:action] == 'edit'
      @contents = @discipline_lesson_plan.lesson_plan.contents_ordered if @discipline_lesson_plan.contents
    else
      @contents = Content.find(@discipline_lesson_plan.lesson_plan.content_ids)
    end

    @contents = @contents.each { |content| content.is_editable = true }.uniq
  end
  helper_method :contents

  def objectives
    @objectives = []

    if params[:action] == 'edit'
      if @discipline_lesson_plan.lesson_plan.objectives
        @objectives = @discipline_lesson_plan.lesson_plan.objectives_ordered
      end
    else
      @objectives = Objective.find(@discipline_lesson_plan.lesson_plan.objective_ids)
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
