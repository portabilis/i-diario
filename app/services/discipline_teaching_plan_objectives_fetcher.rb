class DisciplineTeachingPlanObjectivesFetcher < TeachingPlanObjectivesFetcher
  def initialize(teacher, classroom, discipline, start_date, end_date)
    @teacher = teacher
    @classroom = classroom
    @discipline = discipline
    @start_date = start_date
    @end_date = end_date
  end

  protected

  def base_query
    DisciplineTeachingPlan.includes(teaching_plan: :objectives)
                          .by_unity(@classroom.unity_id)
                          .by_grade(@classroom.grade_id)
                          .by_discipline(@discipline.id)
                          .by_year(school_calendar_year)
                          .by_school_term_type_step_id(school_term_type_steps_ids)
                          .order_by_school_term_type_step
  end
end
