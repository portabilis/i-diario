module DescriptiveExamHelper
  def student_name_class(student_note)
    if student_note.dependence
      'dependence-student'
    else
      ''
    end
  end

  def student_name(student_note)
    if student_note.dependence
      "*#{student_note.student.api_code} - #{student_note.student.to_s}"
    else
      "#{student_note.student.api_code} - #{student_note.student.to_s}"
    end
  end
end
