class UserPolicy < ApplicationPolicy
  def edit?
    return super if @user.admin?
    return super unless @record.has_administrator_access_level?
    return super if @user.has_administrator_access_level?

    false
  end
end
