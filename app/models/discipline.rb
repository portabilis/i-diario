class Discipline < ActiveRecord::Base
  acts_as_copy_target

  has_many :teacher_discipline_classrooms, dependent: :destroy

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  scope :by_teacher_id, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }
  scope :by_teacher_and_classroom, lambda { |teacher_id, classroom_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id }) }
  scope :ordered, -> { order(arel_table[:description].asc) }

  def to_s
    description
  end
end
