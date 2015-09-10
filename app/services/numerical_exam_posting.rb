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
    classrooms = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher = posting.author.teacher

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      classroom = teacher_discipline_classroom.classroom
      discipline = teacher_discipline_classroom.discipline
      step_start_at = posting.school_calendar_step.start_at
      step_end_at = posting.school_calendar_step.end_at

      test_setting = TestSetting.find_by(year: Date.today.year)

      exam_number = Avaliation.where(classroom: classroom,
                                     discipline: discipline
                                     ).count

      if test_setting.fix_tests? && exam_number >= test_setting.tests.count
        students = StudentsFetcher.fetch_students(posting.ieducar_api_configuration, classroom, discipline)

        regular_exam_number = Avaliation.joins(:test_setting_test)
                                        .where(classroom: classroom,
                                               discipline: discipline).count

        students.each do |student|
          exams = DailyNoteStudent.by_classroom_discipline_student_and_avaliation_test_date_between(classroom,
                                                                                                    discipline,
                                                                                                    student.id,
                                                                                                    step_start_at,
                                                                                                    step_end_at)

          if exams.count < regular_exam_number
            raise IeducarApi::Base::ApiError.new("Não é possível enviar as notas pois o aluno "+student.to_s+" não possui todas notas lançadas para a etapa atual.")
          else
            classrooms[classroom.api_code]["turma_id"] = classroom.api_code
            classrooms[classroom.api_code]["alunos"][student.api_code]["aluno_id"] = student.api_code
            classrooms[classroom.api_code]["alunos"][student.api_code]["componentes_curriculares"][discipline.api_code]["componente_curricular_id"] = discipline.api_code

            value = exams.sum(:note)

            classrooms[classroom.api_code]["alunos"][student.api_code]["componentes_curriculares"][discipline.api_code]["valor"] = value
          end
        end

      elsif exam_number > 0
        students = StudentsFetcher.fetch_students(posting.ieducar_api_configuration, classroom, discipline)

        students.each do |student|
          exams = DailyNoteStudent.by_classroom_discipline_student_and_avaliation_test_date_between(classroom,
              discipline, student.id, step_start_at, step_end_at)

          if exams.count < exam_number
            raise IeducarApi::Base::ApiError.new("Não é possível enviar as notas pois o aluno "+student.to_s+" não possui todas notas lançadas para a etapa atual.")
          else
            classrooms[classroom.api_code]["turma_id"] = classroom.api_code
            classrooms[classroom.api_code]["alunos"][student.api_code]["aluno_id"] = student.api_code
            classrooms[classroom.api_code]["alunos"][student.api_code]["componentes_curriculares"][discipline.api_code]["componente_curricular_id"] = discipline.api_code
            classrooms[classroom.api_code]["alunos"][student.api_code]["componentes_curriculares"][discipline.api_code]["valor"] = (exams.sum(:note) / exam_number).round(test_setting.number_of_decimal_places)
          end
        end
      end
    end
    classrooms
  end
end
