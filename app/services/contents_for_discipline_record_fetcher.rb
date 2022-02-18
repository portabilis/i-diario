class ContentsForDisciplineRecordFetcher < ContentsRecordFetcher
  def initialize(teacher, classroom, discipline, date)
    @teacher = teacher
    @classroom = classroom
    @discipline = discipline
    @date = date
  end

  private

  def lesson_plans
    @lesson_plans ||= DisciplineLessonPlan.includes(lesson_plan: :contents)
                                          .by_classroom_id(@classroom.id)
                                          .by_discipline_id(@discipline.id)
                                          .by_date(@date)
  end

  def teaching_plans
    @teaching_plans ||= DisciplineTeachingPlan.includes(teaching_plan: :contents)
                                              .by_unity(@classroom.unity_id)
                                              .by_grade(@classroom.grade_ids)
                                              .by_discipline(@discipline.id)
                                              .by_year(school_calendar_year)
  end
end
