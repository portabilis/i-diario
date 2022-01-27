class YearsFromStudentFetcher
  def fetch(student_id)
    student_enrollment_classrooms = StudentEnrollmentClassroom.by_student(student_id).includes(:classrooms_grade)

    return if student_enrollment_classrooms.nil?

    years = student_enrollment_classrooms.map { |student_enrollment_classroom|
      student_enrollment_classroom&.classrooms_grade&.classroom&.year
    }

    years.compact.uniq.sort.reverse
  end

  def fetch_to_json(student_id)
    years = fetch(student_id).map { |year|
      { id: year, name: year, text: year }
    }
    years.to_json
  end
end
