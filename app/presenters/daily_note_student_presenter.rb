class DailyNoteStudentPresenter < BasePresenter
  def student_name_class
    name_class = 'multiline '

    if in_active_search
      name_class += 'in-active-search'
    elsif !active
      name_class += 'inactive-student'
    elsif exempted
      name_class += 'exempted-student'
    elsif dependence
      name_class += 'dependence-student'
    elsif exempted_from_discipline
      name_class += 'exempted-student-from-discipline'
    end

    name_class
  end

  def student_name
    if in_active_search
      "*****#{student}"
    elsif !active
      "***#{student}"
    elsif exempted
      "**#{student}"
    elsif dependence
      "*#{student}"
    elsif exempted_from_discipline
      "****#{student}"
    else
      student.to_s
    end
  end

  def number_of_decimal_places
    daily_note.avaliation
              .test_setting
              .number_of_decimal_places
  end
end
