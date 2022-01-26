class YearsFromStudentFetcher
  def fetch(student_id)
    student_enrollment_classrooms = StudentEnrollmentClassroom.by_student(student_id).includes(:classroom)
    return if student_enrollment_classrooms.nil?

    years = student_enrollment_classrooms.map do |student_enrollment_classroom|
      next if student_enrollment_classroom.classrooms_grades.nil?

      student_enrollment_classroom.classrooms_grades.map do |classroom_grade|
        classroom_grade.classroom.year
      end
    end
    years.compact.uniq.sort.reverse
  end

  def fetch_to_json(student_id)
    years = fetch(student_id).map { |year|
      { id: year, name: year, text: year }
    }
    years.to_json
  end
end
