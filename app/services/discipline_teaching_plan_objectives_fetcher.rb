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
    discipline_teaching_plans = basic_query.by_school_term(school_terms)

    return discipline_teaching_plans if discipline_teaching_plans.exists?

    basic_query.by_school_term(YEARLY_SCHOOL_TERM_TYPE)
  end

  private

  def basic_query
    @basic_query ||= DisciplineTeachingPlan.includes(teaching_plan: :objectives)
                                           .by_unity(@classroom.unity_id)
                                           .by_grade(@classroom.grade_id)
                                           .by_discipline(@discipline.id)
                                           .by_year(school_calendar_year)
  end
end
