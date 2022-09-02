class DisciplinesController < ApplicationController
  respond_to :json

  has_scope :by_unity_id
  has_scope :by_teacher_id
  has_scope :by_grade
  has_scope :by_classroom

  def index
    return unless current_teacher.present?

    params[:by_classroom] = params[:classroom_id]

    step_id = params[:step_id] || params[:school_calendar_classroom_step_id] || params[:school_calendar_step_id]

    classroom = Classroom.find(params[:classroom_id])
    step_fetcher = StepsFetcher.new(classroom)
    step_number = step_fetcher.step_by_id(step_id).try(:step_number)
    exempted_discipline_ids = ExemptedDisciplinesInStep.discipline_ids(classroom.id, step_number)

    @disciplines = apply_scopes(Discipline).by_teacher_id(current_teacher.id).order_by_sequence

    if params[:conceptual]
      school_calendar = step_fetcher.school_calendar
      student_grade_id = ClassroomsGrade.by_student_id(params[:student_id])
                                        .by_classroom_id(classroom.id)
                                        .first
                                        .grade_id
      disciplines_in_grade_ids = SchoolCalendarDisciplineGrade.where(
        school_calendar_id: school_calendar.id,
        grade_id: student_grade_id
      ).pluck(:discipline_id)

      @disciplines = @disciplines.by_score_type(ScoreTypes::CONCEPT, params[:student_id])
                                 .where(id: disciplines_in_grade_ids)

    end

    @disciplines = @disciplines.where.not(id: exempted_discipline_ids) if exempted_discipline_ids.present?

    @disciplines
  end

  def search
    params[:filter][:by_teacher_id] = current_user.teacher_id if params[:use_user_teacher]
    @disciplines = apply_scopes(Discipline).ordered

    render json: @disciplines
  end

  def search_grouped_by_knowledge_area
    disciplines = Discipline.by_teacher_and_classroom(params[:filter][:teacher_id], params[:filter][:classroom_id])
                            .grouped_by_knowledge_area

    render json: disciplines.as_json
  end

  def by_classroom
    return nil if params[:classroom_id].blank?

    render json: disciplines_to_select2(params[:classroom_id])
  end

  def disciplines_to_select2(classroom_id)
    disciplines = Discipline.by_classroom_id(classroom_id)

    if current_user.teacher?
      disciplines.by_teacher_id(current_teacher.id)
    end

    disciplines.map do |discipline|
      OpenStruct.new(
        id: discipline.id,
        name: discipline.description.to_s,
        text: discipline.description.to_s
      )
    end
  end
end
