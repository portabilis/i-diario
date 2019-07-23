class DescriptiveExamPolicy < ApplicationPolicy
  def new?
    index?
  end

  def edit?
    index?
  end
end
