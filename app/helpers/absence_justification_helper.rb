module AbsenceJustificationHelper
  def absence_justification_destroy?(absence_justification)
    absence_justification.teacher.id == current_teacher.try(:id) || current_user.current_role_is_admin_or_employee?
  end
end
