class SchoolCalendarPolicy < ApplicationPolicy
  def edit?
    index?
  end

  def close?
    edit?
  end
end
