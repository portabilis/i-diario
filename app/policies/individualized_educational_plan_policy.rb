class IndividualizedEducationalPlanPolicy < ApplicationPolicy
  # Permissões por feature herdadas de ApplicationPolicy (can_show?/can_change?).
  # TODO(PEI): definir a matriz de permissões por perfil (criação/finalização).

  def finalize?
    update?
  end
end
