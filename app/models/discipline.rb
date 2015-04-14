class Discipline < ActiveRecord::Base
  acts_as_copy_target

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  def to_s
    description
  end
end
