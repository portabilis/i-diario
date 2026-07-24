class IndividualizedEducationalPlanPolicy < ApplicationPolicy
  # Permissões por feature herdadas de ApplicationPolicy (can_show?/can_change?), com o
  # refino por perfil do PEI:
  # - Administrador e servidor: veem tudo e editam tudo;
  # - Professor: vê tudo, mas NÃO cria nem exclui — edita apenas as seções 4/5 do próprio
  #   componente (a restrição de seção/componente é aplicada no controller) e pode finalizar.
  def create?
    super && user.current_role_is_admin_or_employee?
  end

  def destroy?
    super && user.current_role_is_admin_or_employee?
  end

  def finalize?
    update?
  end
end
