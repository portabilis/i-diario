class NumericalExamPosting
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    api.send_post(turmas: post_classrooms, etapa: posting.school_calendar_step.to_number)
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
      classroom = teacher_discipline_classroom.classroom
      discipline = teacher_discipline_classroom.discipline
      step_start_at = posting.school_calendar_step.start_at
      step_end_at = posting.school_calendar_step.end_at

      number_of_exams = Avaliation.by_classroom_id(classroom.id)
                                  .by_discipline_id(discipline.id)
                                  .by_test_date_between(step_start_at, step_end_at)
                                  .count

      if test_setting.fix_tests? && number_of_exams >= test_setting.tests.count
        students = StudentsFetcher.fetch_students(posting.ieducar_api_configuration, classroom, discipline)

        students.each do |student|
          number_of_student_exams = DailyNoteStudent.by_classroom_discipline_student_and_avaliation_test_date_between(classroom,
                                                                                                                      discipline,
                                                                                                                      student.id,
                                                                                                                      step_start_at,
                                                                                                                      step_end_at)

          if number_of_student_exams.count < regular_exam_number
            raise IeducarApi::Base::ApiError.new("Não é possível enviar as notas pois o aluno #{student.to_s} não possui todas notas lançadas para a etapa informada.")
          else
            value = number_of_student_exams.sum(:note)

            classrooms[classroom.api_code]['turma_id'] = classroom.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['aluno_id'] = student.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['componentes_curriculares'][discipline.api_code]['componente_curricular_id'] = discipline.api_code
            classrooms[classroom.api_code]['alunos'][student.api_code]['componentes_curriculares'][discipline.api_code]['valor'] = value
          end
        end
      elsif number_of_exams > 0
        students = StudentsFetcher.fetch_students(posting.ieducar_api_configuration, classroom, discipline)

        students.each do |student|
          number_of_student_exams = DailyNoteStudent.by_classroom_discipline_student_and_avaliation_test_date_between(classroom,
                                                                                                                      discipline,
                                                                                                                      student.id,
                                                                                                                      step_start_at,
                                                                                                                      step_end_at)

          if number_of_student_exams.count < number_of_exams
            raise IeducarApi::Base::ApiError.new("Não é possível enviar as notas pois o aluno #{student.to_s} não possui todas notas lançadas para a etapa informada.")
          else
            value = (number_of_student_exams.sum(:note) / number_of_exams).round(test_setting.number_of_decimal_places)

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
