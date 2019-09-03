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
    user_id = if @employee_or_admin
                teacher_id = @current_user.try(:assumed_teacher_id)
                User.find_by(teacher_id: teacher_id).try(:id)
              else
                @current_user.try(:id)
              end

    @component.user.try(:id) == user_id && !@component.user.nil?
  end
end
