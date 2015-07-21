class RoundingTableValue < ActiveRecord::Base
  acts_as_copy_target
  belongs_to :rounding_table

  validates :label, :rounding_table_api_code, :value, presence: true

  scope :ordered, -> { order(arel_table[:value].desc) }

  def to_s
    label
  end
end
