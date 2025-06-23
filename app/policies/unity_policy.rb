class UnityPolicy < ApplicationPolicy
  def manage_school_calendars?
    user.can_change?(:manage_school_years_of_the_unit)
  end
end
