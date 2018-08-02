class ComplementaryExamSettingFetcher
  def initialize(classroom, discipline, step, complementary_exam_id = nil)
    @classroom = classroom
    @discipline = discipline
    @step = step
    @complementary_exam_id = complementary_exam_id
  end

  def settings
    @complementary_exam_settings ||= ComplementaryExamSettings
      .by_grade_id(classroom.grade_id)
      .where(" NOT EXISTS (#{not_exists_condition})")
      .ordered
  end

  private

  def not_exists_condition
    ComplementaryExam.by_grade_id(classroom.grade_id)
                     .by_discipline_id(discipline.id)
                     .by_date_range(step.start_at, step.end_at)
                     .where('complementary_exams.complementary_exam_setting_id = complementary_exam_settings.id')
                     .to_sql
  end
end
