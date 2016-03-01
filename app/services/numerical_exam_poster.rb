class NumericalExamPoster
  def initialize(post_data)
    @post_data = post_data
  end

  def self.post!(post_data)
    new(post_data).post!
  end

  def post!
    scores = Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) }

    classroom_ids = teacher.teacher_discipline_classrooms.pluck(:classroom_id).uniq

    classroom_ids.each do |classroom|
      teacher_discipline_classrooms = teacher.teacher_discipline_classrooms.where(classroom_id: classroom)

      teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        classroom = teacher_discipline_classroom.classroom
        discipline = teacher_discipline_classroom.discipline

        next if !correct_score_type(classroom.exam_rule.score_type)
        next if !same_unity(classroom.unity_id)

        exams = Avaliation.by_classroom_id(classroom.id)
          .by_discipline_id(discipline.id)
          .by_test_date_between(step_start_at, step_end_at)
        number_of_exams = exams.count

        daily_notes = DailyNote.by_classroom_id(classroom.id)
          .by_discipline_id(discipline.id)
          .by_test_date_between(step_start_at, step_end_at)

          validate_exam_quantity(number_of_exams)
          validate_exam_quantity_for_fix_test(number_of_exams)
          validate_pending_exams(daily_notes, number_of_exams)

          student_ids = fetch_student_ids(daily_notes)
          students = Student.find(student_ids)
          student_scores = fetch_student_scores(students, classroom, discipline)

          student_scores.each do |student_score|
            value = StudentAverageCalculator.new(student_score).calculate(discipline.id, @post_data.school_calendar_step.id)
            scores['componentes_curriculares'][student_score.api_code]['valor'] = value
            scores['componentes_curriculares'][student_score.api_code]['componente_curricular_id'] = discipline.api_code
          end

          api.send_post(notas: scores , etapa: @post_data.school_calendar_step.to_number, turma_id: classroom.api_code)
        end
      end
    end

  private

  def api
    IeducarApi::PostExams.new(@post_data.to_api)
  end

  private

  def test_setting
    test_setting = TestSetting.find_by(year: @post_data.school_calendar_step.start_at.year, exam_setting_type: ExamSettingTypes::GENERAL)
    if test_setting.nil?
      school_term = @post_data.school_calendar_step.school_calendar.school_term(@post_data.school_calendar_step.start_at)
      test_setting = TestSetting.find_by(year: @post_data.school_calendar_step.start_at.year, school_term: school_term)
    end
    test_setting
  end

  def teacher
    @post_data.author.teacher
  end

  def same_unity(unity_id)
    unity_id == @post_data.school_calendar_step.school_calendar.unity_id
  end

  def correct_score_type(score_type)
    score_type == ScoreTypes::NUMERIC
  end

  def fetch_student_scores(students, classroom, discipline)
    students.each do |student|
      student_exams = DailyNoteStudent.by_classroom_discipline_student_and_avaliation_test_date_between(
        classroom,
        discipline,
        student.id,
        step_start_at,
        step_end_at
      )

      pending_exams = student_exams.select { |e| e.note.blank? }

      if pending_exams.any?
        pending_exams_string = pending_exams.map { |e| e.daily_note.avaliation.description_to_teacher }.join(', ')
        raise IeducarApi::Base::ApiError.new("Não foi possível enviar as avaliações numéricas da turma #{classroom} pois existem avaliações que não foram lançadas no diário de avaliações numéricas para a disciplina #{discipline} para o aluno #{student}. Avaliações: #{pending_exams_string}.")
      end
    end
  end

  def step_start_at
    @post_data.school_calendar_step.start_at
  end

  def step_end_at
    @post_data.school_calendar_step.end_at
  end

  def fetch_student_ids(daily_notes)
    student_ids = []
    daily_notes.each { |d| student_ids << d.students.map(&:student_id) }
    student_ids.flatten!.uniq! if student_ids.any?
    student_ids
  end

  def validate_exam_quantity(number_of_exams)
    if number_of_exams == 0
      raise IeducarApi::Base::ApiError.new("Não foi possível enviar as avaliações numéricas da turma #{classroom} pois não foram cadastradas avaliações numéricas para a disciplina #{discipline}.")
    end
  end

  def validate_exam_quantity_for_fix_test(number_of_exams)
    return unless test_setting.fix_tests?
    if number_of_exams < test_setting.tests.count
      raise IeducarApi::Base::ApiError.new("Não foi possível enviar as avaliações numéricas da turma #{classroom} pois não foram cadastradas todas as avaliações numéricas da configuração de avaliações numéricas para a disciplina #{discipline}.")
    end
  end

  def validate_pending_exams(daily_notes, number_of_exams)
    if daily_notes.count < number_of_exams
      pending_exams = exams.select { |exam| daily_notes.none? { |daily_note| daily_note.avaliation_id == exam.id } }
      pending_exams_string = pending_exams.map(&:description_to_teacher).join(', ')
      raise IeducarApi::Base::ApiError.new("Não foi possível enviar as avaliações numéricas da turma #{classroom} pois existem avaliações que não foram lançadas no diário de avaliações numéricas para a disciplina #{discipline}. Avaliações: #{pending_exams_string}.")
    end
  end
end
