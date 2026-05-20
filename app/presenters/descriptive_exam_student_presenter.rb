class DescriptiveExamStudentPresenter < BasePresenter
  def student_name
    "#{student.api_code} - #{student}"
  end

  def status_badge
    return :active_search            if in_active_search
    return :inactive                 if inactive_student
    return :dependence               if dependence
    return :exempted_from_discipline if exempted_from_discipline
  end
end
