class RecoveryDiaryRecordStudentPresenter < BasePresenter
  def student_name_class
    name_class = 'multiline '
    name_class += 'exempted-student-from-discipline' if exempted_from_discipline

    name_class
  end

  def student_name
    if exempted_from_discipline
      "****#{student}"
    else
      student
    end
  end
end
