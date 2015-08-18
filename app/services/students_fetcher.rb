class StudentsFetcher

  def self.fetch_students ieducar_api_configuration, classroom, discipline = nil
    students = []
    begin
      api = IeducarApi::Students.new(ieducar_api_configuration.to_api)
      result = api.fetch_for_daily({ classroom_api_code: classroom.api_code, discipline_api_code: discipline.try(:api_code)})

      result["alunos"].each do |api_student|
        if student = Student.find_by(api_code: api_student['id'])
          students << student
        end
      end
    end
    students
  end
end
