class TeachingPlanDecorator
  include Decore
  include Decore::Proxy

  def author(current_teacher)
    return I18n.t('enumerations.plans_authors.my_plans') if my_plans?(current_teacher)

    I18n.t('enumerations.plans_authors.others')
  end

  private

  def my_plans?(current_teacher)
    component.teacher.try(:id) == current_teacher.try(:id) && !component.teacher.nil?
  end
end
