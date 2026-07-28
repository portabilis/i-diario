class IndividualizedEducationalPlanPolicy < ApplicationPolicy
  # Permissões por feature herdadas de ApplicationPolicy (can_show?/can_change?), com o
  # refino por perfil do PEI. Isto controla o acesso à ação, não a visibilidade de registro —
  # o alcance de quais planos cada perfil enxerga é decidido em accessible_plans (concern):
  # - Administrador e servidor: create?/new?/destroy? true — criam, editam e excluem o plano;
  # - Professor: index?/show?/update?/finalize? true, mas create?/new?/destroy? false — não
  #   cria nem exclui o PLANO; edita apenas as seções 4/5 do próprio componente (a restrição de
  #   seção/componente é aplicada no controller), incluindo adicionar/excluir as linhas dele.
  # new? espelha create? e é o que a view usa para esconder o botão "Novo" do professor.
  def create?
    # current_role primeiro: curto-circuita sem pagar a query do super para todo professor.
    user.current_role_is_admin_or_employee? && super
  end

  def destroy?
    user.current_role_is_admin_or_employee? && super
  end

  def finalize?
    update?
  end
end
