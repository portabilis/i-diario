class PlanAuthorFetcher
  def initialize(component, current_teacher)
    @component = component
    @current_teacher = current_teacher
  end

  def author
    return I18n.t('enumerations.plans_authors.my_plans') if my_plans?

    I18n.t('enumerations.plans_authors.others')
  end

  private

  def my_plans?
    @component.teacher.try(:id) == @current_teacher.try(:id) && !@component.teacher.nil?
  end
end
