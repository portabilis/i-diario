class Grade < ActiveRecord::Base
  acts_as_copy_target

  belongs_to :course
  has_many :classrooms

  validates :description, :api_code, :course, presence: true
  validates :api_code, uniqueness: true

  scope :ordered, -> { order(arel_table[:description].asc) }

  def to_s
    description
  end
end
