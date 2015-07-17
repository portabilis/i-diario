class RoundingTable < ActiveRecord::Base
  acts_as_copy_target

  validates :label, :api_code, :value, presence: true

  scope :ordered, -> { order(arel_table[:label].asc) }

  def to_s
    label
  end
end
