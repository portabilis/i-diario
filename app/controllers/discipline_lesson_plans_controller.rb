class DisciplineLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher

  def index
    author_type = (params[:filter] || []).delete(:by_author)

    @discipline_lesson_plans = apply_scopes(
      DisciplineLessonPlan.includes(:discipline, lesson_plan: [:classroom])
                          .by_unity_id(current_user_unity.id)
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
    @form = DisciplineLessonPlanClonerForm.new(clone_params)
    if @form.clone!
      flash[:success] = "Plano de aula por disciplina copiado com sucesso!"
    end
  end

  private

  def resource_params
    params.require(:discipline_lesson_plan).permit(
      :lesson_plan_id,
      :discipline_id,
      :classes,
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
    params.require(:discipline_lesson_plan_cloner_form).permit(:discipline_lesson_plan_id,
                                                               discipline_lesson_plan_item_cloner_form_attributes: [
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

  def fetch_disciplines
    Discipline.where(id: current_user_discipline)
      .ordered
  end
end
