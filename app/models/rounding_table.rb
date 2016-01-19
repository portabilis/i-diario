class RoundingTable < ActiveRecord::Base
  acts_as_copy_target

  has_many :rounding_table_values, -> { ordered }

  validates :name, :api_code, presence: true

  def to_s
    name
  end

  def values
    rounding_table_values
  end
end
