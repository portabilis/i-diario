module LessonPlanHelper
  def lesson_plan_destroy?(lesson_plan)
    lesson_plan.teacher.id == current_teacher.try(:id) || current_user.current_role_is_admin_or_employee?
  end
end
