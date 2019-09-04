class UserDiscriminatorService
  def initialize(user, admin_or_employee)
    @user = user
    @admin_or_employee = admin_or_employee
  end

  def user_id
    teacher_id = @user.try(:assumed_teacher_id)

    @user_id ||= if @employee_or_admin && teacher_id
                   User.find_by(teacher_id: teacher_id).try(:id)
                 else
                   @user.try(:id)
                 end
  end
end
