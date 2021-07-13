class YearsFromStudentFetcher
  def initialize(student_id)
    @student_id = student_id
  end

  def fetch
    student_enrollment_classrooms = StudentEnrollmentClassroom.by_student(@student_id)
    return if student_enrollment_classrooms.nil?

    years = []
    student_enrollment_classrooms.each do |student_enrollment_classroom|
      years << student_enrollment_classroom.classroom.year
    end
    years.sort
  end

  def fetch_to_json
    years = fetch
    years_to_json = []
    years.each do |year|
      years_to_json << { id: year, name: year, text: year }
    end
    years_to_json.to_json
  end
end
