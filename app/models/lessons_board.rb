class LessonsBoard < ActiveRecord::Base
  include Discardable
  include Filterable

  audited

  validates :period, presence: true
  validates :classroom_id, presence: true, uniqueness: { scope: :period }


  belongs_to :classroom
  has_many :lessons_board_lessons, dependent: :destroy

  attr_accessor :unity, :grade, :lessons_number

  accepts_nested_attributes_for :lessons_board_lessons, allow_destroy: true


  default_scope -> { kept }

  scope :by_year, ->(year) { joins(:classroom).where(classrooms: { year: year }) }
  scope :by_unity, ->(unity) { joins(:classroom).where(classrooms: { unity_id: unity }) }
  scope :by_grade, ->(grade) { joins(:classroom).where(classrooms: { grade_id: grade }) }
  scope :by_classroom, ->(classroom) { where(classroom_id: classroom) }
  scope :by_teacher, ->(teacher_id) { joins(lessons_board_lessons: [lessons_board_lesson_weekdays: [:teacher_discipline_classroom]])
                                      .where(teacher_discipline_classrooms:  { teacher_id: teacher_id }) }
  scope :by_discipline, ->(discipline_id) { joins(lessons_board_lessons: [lessons_board_lesson_weekdays: [:teacher_discipline_classroom]])
                                            .where(teacher_discipline_classrooms:  { discipline_id: discipline_id }) }
  scope :ordered, -> { order(created_at: :desc) }

end
