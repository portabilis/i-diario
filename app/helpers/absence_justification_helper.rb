module AbsenceJustificationHelper
  def absence_justification_destroy?(absence_justification)
    absence_justification.teacher.id == current_teacher.try(:id) || current_user_role_is_employee_or_administrator?
  end
end
