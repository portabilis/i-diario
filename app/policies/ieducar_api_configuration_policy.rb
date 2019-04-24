class IeducarApiConfigurationPolicy < ApplicationPolicy
  def edit?
    index?
  end
end
