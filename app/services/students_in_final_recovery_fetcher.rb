class StudentsInFinalRecoveryFetcher
  def initialize(ieducar_api_configuration)
    @ieducar_api_configuration = ieducar_api_configuration
  end

  def fetch(classroom_id, discipline_id)
    classroom_api_code = Classroom.find(classroom_id).api_code
    discipline_api_code = Discipline.find(discipline_id).api_code

    result = api.fetch(
      classroom_api_code: classroom_api_code,
      discipline_api_code: discipline_api_code
    )

    api_students = result['alunos']
    students_api_codes = api_students.map { |api_student|
      api_student['id']
    }

    students = Student.where(api_code: students_api_codes).ordered

    students.map do |student|
      needed_score = api_students.find { |api_student|
        api_student['id'].to_s == student.api_code
      }['nota_exame'].to_f

      decorated_student = StudentInFinalRecoveryDecorator.new(student)
      decorated_student.needed_score = needed_score
      decorated_student
    end
  end

  private

  def api
    IeducarApi::StudentsInFinalRecovery.new(@ieducar_api_configuration.to_api)
  end
end
