class LessonsBoardPolicy < ApplicationPolicy
  def new?
    return super if @user.admin? || @user.employee?

    false
  end

  def edit?
    return super if @user.admin? || @user.employee?

    false
  end

  def show?
    return super if @user.admin? || @user.employee?

    false
  end
end
