class LearningObjectivesAndSkillPolicy < ApplicationPolicy
  def import?
    user.admin?
  end
end
