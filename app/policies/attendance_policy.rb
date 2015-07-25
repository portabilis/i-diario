class AttendancePolicy < ApplicationPolicy
  protected

  def feature_name
    'attendance'
  end
end
