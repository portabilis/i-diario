class ContentsForKnowledgeAreaRecordFetcher
  def initialize(teacher, classroom, knowledge_area, date)
    @teacher = teacher
    @classroom = classroom
    @knowledge_area = knowledge_area
    @date = date
  end

  def fetch
    @contents = []
    lesson_plans = KnowledgeAreaLessonPlan.by_classroom_id(@classroom.id)
                                       .by_knowledge_area_id(@knowledge_area.id)
                                       .by_teacher_id(@teacher.id)
                                       .by_date(@date)

    if lesson_plans.any?
      @contents = lesson_plans.map(&:contents)
    end

    teaching_plans = KnowledgeAreaTeachingPlan.by_grade(@classroom.grade.id)
                                           .by_knowledge_area(@knowledge_area.id)
                                           .by_year(@date.to_date.year)
                                           .by_teacher(@teacher.id)

    if @contents.blank? && teaching_plans.any?
      @contents = teaching_plans.map(&:contents)
    end

    @contents.uniq.flatten
  end
end
