class LessonPlanPolicy < ApplicationPolicy
  def update?
    @user.employee? || @user.administrator?
  end
end
