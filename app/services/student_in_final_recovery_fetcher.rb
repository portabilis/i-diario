class StudentInFinalRecoveryFetcher
  def initialize(ieducar_api_configuration)
    @ieducar_api_configuration = ieducar_api_configuration
  end

  def fetch(classroom_id, discipline_id, student_id)
    classroom_api_code = Classroom.find(classroom_id).api_code
    discipline_api_code = Discipline.find(discipline_id).api_code
    student_api_code = Student.find(student_id).api_code

    result = api.fetch(
      classroom_api_code: classroom_api_code,
      discipline_api_code: discipline_api_code
    )

    api_students = result['alunos']

    student = Student.find_by(api_code: student_api_code)
    decorated_student = StudentInFinalRecoveryDecorator.new(student)
    api_result = api_students.find { |api_student| api_student['id'] == student.api_code }
    if api_result
      decorated_student.needed_score = api_result['nota_exame'].to_f
    end
    decorated_student
  end

  private

  def api
    IeducarApi::StudentsInFinalRecovery.new(@ieducar_api_configuration.to_api)
  end
end
