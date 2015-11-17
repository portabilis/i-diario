module IeducarApi
  class StudentsInFinalRecovery < Base
    def fetch(classroom_api_code, discipline_api_code)
      students_api_codes = Student.limit(20).map { |student| { id: student.api_code } }
      {
        alunos: students_api_codes
      }
    end
  end
end
