class Discipline < ActiveRecord::Base
  acts_as_copy_target

  has_many :teacher_discipline_classrooms, dependent: :destroy

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  scope :ordered, -> { order(arel_table[:description].asc) }

  def to_s
    description
  end
end
