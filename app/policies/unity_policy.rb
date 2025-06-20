class UnityPolicy < ApplicationPolicy
  def manage_school_calendars?
    user.admin?
  end
end
