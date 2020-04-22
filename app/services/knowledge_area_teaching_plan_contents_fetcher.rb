class KnowledgeAreaTeachingPlanContentsFetcher < TeachingPlanContentsFetcher
  def initialize(teacher, classroom, knowledge_area_ids, start_date, end_date)
    @teacher = teacher
    @classroom = classroom
    @knowledge_area_ids = knowledge_area_ids
    @start_date = start_date
    @end_date = end_date
  end

  protected

  def base_query
    knowledge_area_teaching_plans = basic_query.by_school_term(school_terms)

    return knowledge_area_teaching_plans if knowledge_area_teaching_plans.exists?

    basic_query.by_school_term(YEARLY_SCHOOL_TERM_TYPE)
  end

  private

  def basic_query
    KnowledgeAreaTeachingPlan.includes(teaching_plan: :contents)
                             .by_unity(@classroom.unity_id)
                             .by_grade(@classroom.grade_id)
                             .by_knowledge_area(@knowledge_area_ids)
                             .by_year(school_calendar_year)
  end
end
