class IndividualizedEducationalPlanPolicy < ApplicationPolicy
  # Permissões por feature herdadas de ApplicationPolicy (can_show?/can_change?).
  # As permissões por perfil ainda serão definidas.

  def finalize?
    update?
  end
end
