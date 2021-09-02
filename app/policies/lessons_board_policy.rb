class LessonsBoardPolicy < ApplicationPolicy
  def new?
    return super if @user.admin? || @user.employee? || @user.can_change?(:lessons_boards)

    false
  end

  def edit?
    return super if @user.admin? || @user.employee? || @user.can_change?(:lessons_boards)

    false
  end

  def show?
    return super if @user.admin? || @user.employee? || @user.can_show?(:lessons_boards)

    false
  end
end
