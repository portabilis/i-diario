class AbsenceJustificationAuthorFetcher
  def initialize(component, current_user, employee_or_admin)
    @component = component
    @current_user = current_user
    @employee_or_admin = employee_or_admin
  end

  def author
    return I18n.t('enumerations.absence_justification_authors.my_justifications') if my_plans?

    I18n.t('enumerations.absence_justification_authors.others')
  end

  private

  def my_plans?
    user_id = UserDiscriminatorService.new(@current_user, @employee_or_admin).user_id

    @component.user.try(:id) == user_id && !@component.user.nil?
  end
end
