module DescriptiveExamHelper
  def descriptive_exam_student_name_class(student_note)
    if student_note.dependence
      'dependence-student'
    elsif student_note.exempted_from_discipline
      'exempted-student-from-discipline'
    else
      ''
    end
  end

  def descriptive_exam_student_name(student_note)
    if student_note.dependence
      "*#{student_note.student.api_code} - #{student_note.student.to_s}"
    elsif student_note.exempted_from_discipline
      "****#{student_note.student.api_code} - #{student_note.student.to_s}"
    else
      "#{student_note.student.api_code} - #{student_note.student.to_s}"
    end
  end
end
