class RoundingTableValue < ActiveRecord::Base
  acts_as_copy_target
  belongs_to :rounding_table

  validates :label, :tabela_arredondamento_id, :value, presence: true

  scope :ordered, -> { order(arel_table[:label].asc) }

  def to_s
    label
  end
end
