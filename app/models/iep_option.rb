class IepOption < ApplicationRecord
  has_enumeration_for :kind, with: IepOptionKinds

  validates :kind, :description, presence: true
  # O kind define a qual dos grupos de multi-select a opção pertence. Sem esta trava,
  # um kind fora da enumeração viraria uma opção órfã (nunca aparece em nenhum grupo).
  validates :kind, inclusion: { in: IepOptionKinds.list }, allow_nil: true

  scope :enabled, -> { where(active: true) }
  scope :ordered, -> { order(:position) }
  scope :by_kind, ->(kind) { where(kind: IepOptionKinds.value_of(kind)) }

  # Rótulo exibido nos selects (select2 usa name/text/to_s como label).
  def to_s
    description
  end
end
