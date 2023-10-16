class KnowledgeAreaTeachingPlanObjectivesFetcher < TeachingPlanObjectivesFetcher
  def initialize(teacher, classroom, knowledge_area_ids, start_date, end_date)
    @teacher = teacher
    @classroom = classroom
    @knowledge_area_ids = knowledge_area_ids
    @start_date = start_date
    @end_date = end_date
  end

  protected

  def base_query
    KnowledgeAreaTeachingPlan.includes(teaching_plan: :objectives)
                             .by_unity(@classroom.unity_id)
                             .by_grade(@classroom.classrooms_grades.map(&:grade_id))
                             .by_knowledge_area(@knowledge_area_ids)
                             .by_year(school_calendar_year)
                             .by_school_term_type_step_id(school_term_type_steps_ids)
                             .order_by_school_term_type_step
  end
end
