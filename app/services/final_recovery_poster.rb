class FinalRecoveryPoster
  def initialize(post_data)
    self.post_data = post_data
  end

  def self.post!(post_data)
    new(post_data).post!
  end

  def post!
    params = build_params
    params.each do |key, value| { api.send_post(turmas: { key => value }) }
  end

  private

  def api
    IeducarApi::FinalRecoveries.new(post_data.to_api)
  end

  def build_params
    params = {}

    teacher = posting.author.teacher

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      next if teacher_discipline_classroom.classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      classroom = teacher_discipline_classroom.classroom

      next if classroom.exam_rule.score_type != ScoreTypes::NUMERIC

      discipline = teacher_discipline_classroom.discipline
    end

    params
  end
end
