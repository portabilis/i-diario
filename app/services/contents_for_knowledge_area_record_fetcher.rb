class ContentsForKnowledgeAreaRecordFetcher
  def initialize(teacher, classroom, knowledge_areas, date)
    @teacher = teacher
    @classroom = classroom
    @knowledge_areas = [knowledge_areas].flatten
    @date = date
  end

  def fetch
    @contents = []
    lesson_plans = KnowledgeAreaLessonPlan.by_classroom_id(@classroom.id)
                                       .by_knowledge_area_id(@knowledge_areas.map(&:id))
                                       .by_teacher_id(@teacher.id)
                                       .by_date(@date)
                                       .includes(lesson_plan: :contents)

    if lesson_plans.any?
      @contents = lesson_plans.map(&:contents)
    end

    teaching_plans = KnowledgeAreaTeachingPlan.by_grade(@classroom.grade.id)
                                           .by_knowledge_area(@knowledge_areas.map(&:id))
                                           .by_year(@date.to_date.year)
                                           .by_teacher_id(@teacher.id)
                                           .includes(teaching_plan: :contents)

    if @contents.blank? && teaching_plans.any?
      @contents = teaching_plans.map(&:contents)
    end

    @contents.flatten.uniq
  end
end
