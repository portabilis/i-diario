class StudentsInFinalRecoveryFetcher
  def initialize(ieducar_api_configuration)
    @ieducar_api_configuration = ieducar_api_configuration
  end

  def fetch(classroom_id, discipline_id)
    classroom_api_code = Classroom.find(classroom_id).api_code
    discipline_api_code = Discipline.find(discipline_id).api_code

    result = api.fetch(classroom_api_code, discipline_api_code)

    api_students = result[:alunos]
    students_api_codes = api_students.map { |api_student| api_student[:id] }

    students = Student.where(api_code: students_api_codes).ordered.map do |student|
      decorated_student = StudentInFinalRecoveryDecorator.new(student)
      decorated_student.needed_score = 5.15
      decorated_student
    end
  end

  private

  def api
    IeducarApi::StudentsInFinalRecovery.new(@ieducar_api_configuration.to_api)
  end
end
