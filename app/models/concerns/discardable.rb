module Discardable
  extend ActiveSupport::Concern

  include Discard::Model

  included do
    # O `undiscard` zera o `discarded_at` antes de rodar os callbacks de `after_undiscard`,
    # então o valor anterior precisa ser capturado aqui — depois ele já é nil.
    before_undiscard { @discarded_at_before_undiscard = discarded_at }
  end

  def discard_or_undiscard(discardable)
    discard if kept? && discardable
    undiscard if discarded? && !discardable
  end

  def kept?
    !discarded?
  end

  private

  # Reativa os dependentes descartados a partir do instante em que este registro foi descartado.
  # O critério é temporal, não causal: dependente descartado ANTES continua descartado (é o que
  # preserva a exclusão feita por outro fluxo), enquanto dependente descartado DEPOIS volta
  # junto, mesmo que tenha caído por outro motivo.
  #
  # A ordem das duas chamadas é obrigatória. `with_discarded` é `unscope(where: discard_column)`,
  # e o unscope remove qualquer predicado sobre essa coluna: inverter para
  # `where(...).with_discarded` apagaria o filtro em silêncio e reativaria todo dependente
  # descartado.
  def undiscard_dependents_discarded_with(dependents)
    return if @discarded_at_before_undiscard.nil?

    discard_column = dependents.klass.discard_column

    dependents.with_discarded
              .where(dependents.klass.arel_table[discard_column].gteq(@discarded_at_before_undiscard))
              .undiscard_all
  end
end
