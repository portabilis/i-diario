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

    if lesson_plans.exists?
      @contents = lesson_plans.map(&:contents)
    end

    if @contents.blank?
      teaching_plans = DisciplineTeachingPlan.by_grade(@classroom.grade.id)
        .by_discipline(@discipline.id)
        .by_year(@date.to_date.year)

      teaching_plans_by_teacher = teaching_plans.by_teacher_id(@teacher.id)
      teaching_plans_by_teacher = teaching_plans.by_teacher_id(nil) unless teaching_plans_by_teacher.exists?

      if teaching_plans_by_teacher.exists?
        @contents = teaching_plans_by_teacher.map(&:contents)
      end
    end

    @contents.uniq.flatten
  end
end
