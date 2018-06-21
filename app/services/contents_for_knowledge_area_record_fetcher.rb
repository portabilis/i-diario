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

    if lesson_plans.exists?
      @contents = lesson_plans.map(&:contents)
    end

    if @contents.blank?
      teaching_plans = KnowledgeAreaTeachingPlan.by_grade(@classroom.grade.id)
        .by_knowledge_area(@knowledge_areas.map(&:id))
        .by_year(@date.to_date.year)
        .includes(teaching_plan: :contents)

      teaching_plans_by_teacher = teaching_plans.by_teacher_id(@teacher.id)
      teaching_plans_by_teacher = teaching_plans.by_teacher_id(nil) unless teaching_plans_by_teacher.exists?

      if teaching_plans_by_teacher.exists?
        @contents = teaching_plans_by_teacher.map(&:contents)
      end
    end

    @contents.flatten.uniq
  end
end
