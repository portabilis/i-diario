class NumericalExamPosting
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    api.send_post(turmas: post_classrooms, etapa: 1)
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

      exam_number = Avaliation.where(classroom: classroom,
                                     discipline: discipline
                                     ).count
      if exam_number > 0
        students = fetch_students(classroom, discipline)
        students.each do |student|
          exams = DailyNoteStudent.by_classroom_discipline_student_and_avaliation_test_date_between(classroom,
              discipline, student.id, step_start_at, step_end_at)

          if exams.count < exam_number
            raise IeducarApi::Base::ApiError.new("Não é possível enviar as notas pois o aluno "+student.to_s+" não possui todas notas lançadas.")
          else
            classrooms[classroom.api_code]["turma_id"] = classroom.api_code
            classrooms[classroom.api_code]["alunos"][student.api_code]["aluno_id"] = student.api_code
            classrooms[classroom.api_code]["alunos"][student.api_code]["componentes_curriculares"][discipline.api_code]["componente_curricular_id"] = discipline.api_code
            classrooms[classroom.api_code]["alunos"][student.api_code]["componentes_curriculares"][discipline.api_code]["valor"] = exams.sum(:note) / exam_number
          end
        end
      end
    end
    classrooms
  end

  def fetch_students classroom, discipline
    students = []
    begin
      api = IeducarApi::Students.new(posting.ieducar_api_configuration.to_api)
      result = api.fetch_for_daily({ classroom_api_code: classroom.api_code, discipline_api_code: discipline.api_code})

      result["alunos"].each do |api_student|
        if student = Student.find_by(api_code: api_student['id'])
          students << student
        end
      end
    end
    students
  end
end
