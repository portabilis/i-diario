class LessonsBoard < ActiveRecord::Base
  include Discardable

  audited

  belongs_to :classroom
  has_many :lessons_board_lessons, dependent: :restrict_with_error

  attr_accessor :unity, :grade, :period, :teacher, :classroom_id

  accepts_nested_attributes_for :lessons_board_lessons, allow_destroy: false


  default_scope -> { kept }

  scope :by_unity_id, ->(unity_id) { joins(:classroom).where(classroom: { unity_id: unity_id }) }
  scope :by_grade_id, ->(grade_id) { joins(:classroom).where(classroom: { grade_id: grade_id }) }
  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_year, ->(year) { joins(:classroom).where(classroom: { year: year }) }
  scope :ordered, -> { order(created_at: :desc) }

end
