class SchoolCalendarPolicy < ApplicationPolicy
  def edit?
    index?
  end
end
