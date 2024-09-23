class DescriptiveExamStudentPresenter < BasePresenter
  def student_name_class
    name_class = 'multiline '

    if dependence
      name_class += 'dependence-student'
    elsif exempted_from_discipline
      name_class += 'exempted-student-from-discipline'
    end

    name_class
  end

  def student_name
    if dependence
      "*#{student.api_code} - #{student}"
    elsif exempted_from_discipline || inactive_student
      "****#{student.api_code} - #{student}"
    else
      "#{student.api_code} - #{student}"
    end
  end
end
