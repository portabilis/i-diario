class DisciplineLessonPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def index
    @discipline_lesson_plans = apply_scopes(DisciplineLessonPlan)
      .includes(:discipline, lesson_plan: [:unity, :classroom])
      .filter(filtering_params(params[:search]))
      .by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)
      .ordered

    authorize @discipline_lesson_plans

    @classrooms = Classroom.by_unity_and_teacher(
        current_user_unity.id,
        current_teacher.id
      )
      .ordered

    @disciplines = Discipline.by_teacher_id(
        current_teacher.id
      )
      .ordered
  end

  def new
    @discipline_lesson_plan = DisciplineLessonPlan.new.localized
    @discipline_lesson_plan.build_lesson_plan
    @discipline_lesson_plan.lesson_plan.school_calendar = current_school_calendar
    @discipline_lesson_plan.lesson_plan.unity = current_user_unity

    authorize @discipline_lesson_plan

    @unities = Unity.by_teacher(current_teacher.id).ordered
    @classrooms =  Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id).ordered
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def create
    @discipline_lesson_plan = DisciplineLessonPlan.new.localized
    @discipline_lesson_plan.assign_attributes(resource_params)
    @discipline_lesson_plan.lesson_plan.school_calendar = current_school_calendar

    authorize @discipline_lesson_plan

    if @discipline_lesson_plan.save
      respond_with @discipline_lesson_plan, location: discipline_lesson_plans_path
    else
      @unities = Unity.by_teacher(current_teacher.id).ordered
      @classrooms =  Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id).ordered
      @number_of_classes = current_school_calendar.number_of_classes

      render :new
    end
  end

  def edit
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id]).localized

    authorize @discipline_lesson_plan

    @unities = Unity.by_teacher(current_teacher.id).ordered
    @classrooms =  Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id).ordered
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def update
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id]).localized
    @discipline_lesson_plan.assign_attributes(resource_params)

    authorize @discipline_lesson_plan

    if @discipline_lesson_plan.save
      respond_with @discipline_lesson_plan, location: discipline_lesson_plans_path
    else
      @unities = Unity.by_teacher(current_teacher.id).ordered
      @classrooms =  Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id).ordered
      @number_of_classes = current_school_calendar.number_of_classes

      render :edit
    end
  end

  def destroy
    @discipline_lesson_plan = DisciplineLessonPlan.find(params[:id])

    @discipline_lesson_plan.destroy

    respond_with @discipline_lesson_plan, location: discipline_lesson_plans_path
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
        :lesson_plan_date,
        :contents,
        :activities,
        :objectives,
        :resources,
        :evaluation,
        :bibliography,
        :opinion
      ]
    )
  end

  def filtering_params(params)
    params = {} unless params
    params.slice(
      :by_classroom_id,
      :by_discipline_id,
      :by_lesson_plan_date
    )
  end
end
