module TeachingPlanHelper
  def teaching_plan_destroy?(teaching_plan)
    current_user.current_role_is_admin_or_employee? || teaching_plan&.teacher&.id == current_teacher.try(:id)
  end

  def discipline_teaching_plan_form_url(discipline_teaching_plan, action_name)
    case action_name
    when 'new', 'create'
      discipline_teaching_plans_path(locale: I18n.locale)
    when 'edit'
      discipline_teaching_plan_path(discipline_teaching_plan)
    when 'show'
      teaching_plan_opinion_path(discipline_teaching_plan.teaching_plan.id, locale: I18n.locale)
    end
  end

  def teaching_plan_form_method(action_name)
    case action_name
    when 'new', 'create'
      :post
    when 'show', 'edit'
      :patch
    end
  end

  def knowledge_area_teaching_plan_form_url(knowledge_area_teaching_plan, action_name)
    case action_name
    when 'new', 'create'
      knowledge_area_teaching_plans_path(locale: I18n.locale)
    when 'edit'
      knowledge_area_teaching_plan_path(knowledge_area_teaching_plan)
    when 'show'
      teaching_plan_opinion_path(knowledge_area_teaching_plan.teaching_plan.id, locale: I18n.locale)
    end
  end
end
