class LessonPlanDecorator
  include Decore
  include Decore::Proxy

  def author(current_teacher)
    return I18n.t('enumerations.plans_authors.my_plans') if component.teacher_id == current_teacher.try(:id)

    I18n.t('enumerations.plans_authors.others')
  end
end
