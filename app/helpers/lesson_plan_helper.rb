module LessonPlanHelper
  def lesson_plan_destroy?(lesson_plan)
    lesson_plan.teacher.id == current_teacher.try(:id) || current_user.current_role_is_admin_or_employee?
  end

  def discipline_lesson_plan_form_url(discipline_lesson_plan, action_name)
    case action_name
    when 'new'
      discipline_lesson_plans_path(locale: I18n.locale)
    when 'edit'
      discipline_lesson_plan_path(discipline_lesson_plan)
    when 'show'
      lesson_plan_opinion_path(discipline_lesson_plan.lesson_plan.id, locale: I18n.locale)
    end
  end

  def lesson_plan_form_method(action_name)
    case action_name
    when 'new', 'create'
      :post
    when 'show'
      :patch
    end
  end

  def knowledge_area_lesson_plan_form_url(knowledge_area_lesson_plan, action_name)
    case action_name
    when 'new', 'create'
      knowledge_area_lesson_plans_path(locale: I18n.locale)
    when 'edit'
      knowledge_area_lesson_plan_path(knowledge_area_lesson_plan)
    when 'show'
      lesson_plan_opinion_path(knowledge_area_lesson_plan.lesson_plan.id, locale: I18n.locale)
    end
  end
end
