class DailyFrequencyPolicy < ApplicationPolicy
  def destroy_multiple?
    update?
  end
end
