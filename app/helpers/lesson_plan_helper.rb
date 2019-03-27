module LessonPlanHelper
  def lesson_plan_destroy?(lesson_plan)
    lesson_plan.teacher_id == current_teacher.try(:id) || current_user_role_is_employee_or_administrator?
  end
end
