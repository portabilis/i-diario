class ConceptualExamPosting
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

      exams = ConceptualExamStudent.by_classroom_discipline_and_step(classroom,discipline, posting.school_calendar_step.id)

      students = StudentsFetcher.fetch_students(posting.ieducar_api_configuration, classroom, discipline)

      if exams.count == students.count
        exams.each do |exam|

          classrooms[classroom.api_code]["turma_id"] = classroom.api_code
          classrooms[classroom.api_code]["alunos"][exam.student.api_code]["aluno_id"] = exam.student.api_code
          classrooms[classroom.api_code]["alunos"][exam.student.api_code]["componentes_curriculares"][discipline.api_code]["componente_curricular_id"] = discipline.api_code
          classrooms[classroom.api_code]["alunos"][exam.student.api_code]["componentes_curriculares"][discipline.api_code]["valor"] = exam.value
        end
      else
        raise IeducarApi::Base::ApiError.new("Não é possível enviar os conceitos pois não foram todos lançados na turma "+classroom.to_s+" e disciplina "+discipline.to_s+" para a etapa atual.")
      end

    end
    classrooms
  end
end
