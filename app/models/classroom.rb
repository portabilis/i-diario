class Classroom < ActiveRecord::Base
  acts_as_copy_target
  belongs_to :unity

  validates :description, :api_code, :unity_code, :year, presence: true
  validates :api_code, uniqueness: true

  def to_s
    description
  end
end
