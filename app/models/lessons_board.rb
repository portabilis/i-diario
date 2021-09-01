class LessonsBoard < ActiveRecord::Base
  include Discardable
  include Filterable

  audited

  validates :classroom_id, :period, presence: true

  belongs_to :classroom
  has_many :lessons_board_lessons, dependent: :destroy

  attr_accessor :unity, :grade

  accepts_nested_attributes_for :lessons_board_lessons, allow_destroy: true


  default_scope -> { kept }

  scope :by_year, ->(year) { joins(:classroom).where(classrooms: { year: year }) }
  scope :by_unity, ->(unity) { joins(:classroom).where(classrooms: { unity_id: unity }) }
  scope :by_grade, ->(grade) { joins(:classroom).where(classrooms: { grade_id: grade }) }
  scope :by_classroom, ->(classroom) { where(classroom_id: classroom) }
  scope :ordered, -> { order(created_at: :desc) }

end
