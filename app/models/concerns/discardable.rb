module Discardable
  extend ActiveSupport::Concern

  include Discard::Model

  included do
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

  # Reativa, entre os dependentes informados, só os que caíram junto com este registro
  # (descartados no mesmo instante ou depois). Dependente excluído antes, por outro motivo,
  # permanece excluído. O `with_discarded` é obrigatório: a relação chega filtrada por
  # `kept`, e sem ele não há o que reativar.
  def undiscard_dependents_discarded_with(dependents)
    discarded_at_column = dependents.klass.arel_table[:discarded_at]

    dependents.with_discarded
              .where(discarded_at_column.gteq(@discarded_at_before_undiscard))
              .undiscard_all
  end
end
