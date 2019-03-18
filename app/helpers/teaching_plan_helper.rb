module TeachingPlanHelper
  def teaching_plan_destroy?(teaching_plan)
    teaching_plan.teacher_id == current_teacher.try(:id) || current_user_role_is_employee_or_administrator?
  end
end
