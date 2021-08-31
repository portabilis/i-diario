class LessonsBoard < ActiveRecord::Base
  include Discardable

  audited

  validates :classroom_id, :period, presence: true

  belongs_to :classroom
  has_many :lessons_board_lessons, dependent: :destroy

  attr_accessor :unity, :grade

  accepts_nested_attributes_for :lessons_board_lessons, allow_destroy: true


  default_scope -> { kept }

  scope :by_unity_id, ->(unity_id) { joins(:classroom).where(classroom: { unity_id: unity_id }) }
  scope :by_grade_id, ->(grade_id) { joins(:classroom).where(classroom: { grade_id: grade_id }) }
  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_year, ->(year) { joins(:classroom).where(classroom: { year: year }) }
  scope :ordered, -> { order(created_at: :desc) }

end
