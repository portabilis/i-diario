class RoundingTable < ActiveRecord::Base
  acts_as_copy_target

  validates :name, :api_code, presence: true

  def to_s
    name
  end
end
