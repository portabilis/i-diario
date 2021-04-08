module TeachingPlanHelper
  def teaching_plan_destroy?(teaching_plan)
    current_user.current_role_is_admin_or_employee? || teaching_plan&.teacher&.id == current_teacher.try(:id)
  end
end
