class UnityPolicy < ApplicationPolicy
  def view_school_calendars?
    user.can_show?(:manage_school_years_of_the_unit)
  end

  def manage_school_calendars?
    user.can_change?(:manage_school_years_of_the_unit)
  end
end
