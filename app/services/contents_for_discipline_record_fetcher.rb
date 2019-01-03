class ContentsForDisciplineRecordFetcher
  def initialize(teacher, classroom, discipline, date)
    @teacher = teacher
    @classroom = classroom
    @discipline = discipline
    @date = date
  end

  def fetch
    @contents = []
    lesson_plans = DisciplineLessonPlan.by_classroom_id(@classroom.id)
                                       .by_discipline_id(@discipline.id)
                                       .by_teacher_id(@teacher.id)
                                       .by_date(@date)

    @contents = lesson_plans.map(&:contents) if lesson_plans.exists?

    if @contents.blank?
      step = StepsFetcher.new(@classroom).step(@date.to_date)
      school_term = step.try(:raw_school_term) || ''

      teaching_plans = DisciplineTeachingPlan.by_grade(@classroom.grade.id)
                                             .by_discipline(@discipline.id)
                                             .by_year(@date.to_date.year)

      teaching_plans = teaching_plans.by_school_term(school_term)
      teaching_plans_by_teacher = teaching_plans.by_teacher_id(@teacher.id)
      teaching_plans_by_teacher = teaching_plans.by_teacher_id(nil) unless teaching_plans_by_teacher.exists?

      @contents = teaching_plans_by_teacher.map(&:contents) if teaching_plans_by_teacher.exists?
    end

    @contents.uniq.flatten
  end
end
