class FinalRecoveryPoster
  def initialize(post_data)
    @post_data = post_data
  end

  def self.post(post_data)
    new(post_data).post
  end

  def post
    params = build_params
    params.each { |key, value| api.send_post(turmas: { key => value }) }
  end

  private

  def api
    IeducarApi::FinalRecoveries.new(@post_data.to_api)
  end

  def build_params
    params = Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) }

    final_recovery_diary_records = fetch_final_recovery_diary_records

    if final_recovery_diary_records.empty?
      raise IeducarApi::Base::ApiError.new("Não foi possível encontrar nenhuma recuperação final lançada.")
    end

    final_recovery_diary_records.each do |final_recovery_diary_record|
      if final_recovery_diary_record.recovery_diary_record.students.any? { |student| student.score.blank? }
        raise IeducarApi::Base::ApiError.new("Não foi possível enviar as recuperações finais da turma #{final_recovery_diary_record.recovery_diary_record.classroom} pois existem alunos sem nota.")
      end

      classroom_api_code = final_recovery_diary_record.recovery_diary_record.classroom.api_code
      discipline_api_code = final_recovery_diary_record.recovery_diary_record.discipline.api_code

      final_recovery_diary_record.recovery_diary_record.students.each do |student|
        params[classroom_api_code]['turma_id'] = classroom_api_code
        params[classroom_api_code]['alunos'][student.student.api_code]['aluno_id'] = student.student.api_code
        params[classroom_api_code]['alunos'][student.student.api_code]['componentes_curriculares'][discipline_api_code]['componente_curricular_id'] = discipline_api_code
        params[classroom_api_code]['alunos'][student.student.api_code]['componentes_curriculares'][discipline_api_code]['valor'] = student.score
      end
    end

    params
  end

  def fetch_final_recovery_diary_records
    final_recovery_diary_records = []

    teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      final_recovery_diary_record = FinalRecoveryDiaryRecord.by_school_calendar_id(@post_data.school_calendar_step.school_calendar_id)
        .by_classroom_id(teacher_discipline_classroom.classroom.id)
        .by_discipline_id(teacher_discipline_classroom.discipline.id)
        .first

      final_recovery_diary_records << final_recovery_diary_record unless final_recovery_diary_record.blank?
    end

    final_recovery_diary_records
  end

  def teacher_discipline_classrooms
    @post_data.author.teacher.teacher_discipline_classrooms.select do |teacher_discipline_classroom|
      valid_unity?(teacher_discipline_classroom.classroom.unity_id) && valid_score_type?(teacher_discipline_classroom.classroom.exam_rule.score_type)
    end
  end

  def valid_unity?(unity_id)
    unity_id == @post_data.school_calendar_step.school_calendar.unity_id
  end

  def valid_score_type?(score_type)
    score_type == ScoreTypes::NUMERIC
  end
end
