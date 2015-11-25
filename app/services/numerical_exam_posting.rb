class NumericalExamPosting
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    post_classrooms.each do |key, value|
      api.send_post(turmas: { key => value }, etapa: posting.school_calendar_step.to_number)
    end
  end

  protected

  attr_accessor :posting

  def api
    IeducarApi::PostExams.new(posting.to_api)
  end

  def post_classrooms
    classrooms = Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) }

    teacher = posting.author.teacher

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      next if teacher_discipline_classroom.classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      classroom = teacher_discipline_classroom.classroom

      next if classroom.exam_rule.score_type != ScoreTypes::NUMERIC

      discipline = teacher_discipline_classroom.discipline
      step_start_at = posting.school_calendar_step.start_at
      step_end_at = posting.school_calendar_step.end_at

      exams = Avaliation.by_classroom_id(classroom.id)
        .by_discipline_id(discipline.id)
        .by_test_date_between(step_start_at, step_end_at)
      number_of_exams = exams.count

      daily_notes = DailyNote.by_classroom_id(classroom.id)
        .by_discipline_id(discipline.id)
        .by_test_date_between(step_start_at, step_end_at)

      if number_of_exams == 0
        raise IeducarApi::Base::ApiError.new("Não foi possível enviar as avaliações numéricas da turma #{classroom} pois não foram cadastradas avaliações numéricas para a disciplina #{discipline}.")
      elsif test_setting.fix_tests? && number_of_exams < test_setting.tests.count
        raise IeducarApi::Base::ApiError.new("Não foi possível enviar as avaliações numéricas da turma #{classroom} pois não foram cadastradas todas as avaliações numéricas da configuração de avaliações numéricas para a disciplina #{discipline}.")
      elsif daily_notes.count < number_of_exams
        pending_exams = exams.select { |exam| daily_notes.none? { |daily_note| daily_note.avaliation_id == exam.id } }
        pending_exams_string = pending_exams.map(&:description_to_teacher).join(', ')
        raise IeducarApi::Base::ApiError.new("Não foi possível enviar as avaliações numéricas da turma #{classroom} pois existem avaliações que não foram lançadas no diário de avaliações numéricas para a disciplina #{discipline}. Avaliações: #{pending_exams_string}.")
      else
        students_ids = []
        daily_notes.each { |d| students_ids << d.students.map(&:student_id) }
        students_ids.flatten!.uniq! if students_ids.any?
        students = Student.find(students_ids)

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
          else
            value = test_setting.fix_tests? ? student_exams.sum(:note) : (student_exams.sum(:note) / number_of_exams).round(test_setting.number_of_decimal_places)

            classrooms[classroom.api_code]['turma_id'] = classroom.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['aluno_id'] = student.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['componentes_curriculares'][discipline.api_code]['componente_curricular_id'] = discipline.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['componentes_curriculares'][discipline.api_code]['valor'] = value
          end
        end
      end
    end

    classrooms
  end

  private

  def test_setting
    test_setting = TestSetting.find_by(year: posting.school_calendar_step.start_at.year, exam_setting_type: ExamSettingTypes::GENERAL)
    if test_setting.nil?
      school_term = posting.school_calendar_step.school_calendar.school_term(posting.school_calendar_step.start_at)
      test_setting = TestSetting.find_by(year: posting.school_calendar_step.start_at.year, school_term: school_term)
    end
    test_setting
  end
end
