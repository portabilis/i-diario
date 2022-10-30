class LessonsBoard < ActiveRecord::Base
  include Audit
  include Discardable
  include Filterable

  audited

  validates :period, :classrooms_grade_id, presence: true

  belongs_to :classrooms_grade
  has_many :lessons_board_lessons

  attr_accessor :unity, :grade, :lessons_number, :classroom_id

  accepts_nested_attributes_for :lessons_board_lessons, allow_destroy: true

  delegate :classroom, :classroom_id, :grade_id, to: :classrooms_grade, allow_nil: true
  delegate :unity_id, to: :classroom, allow_nil: true

  default_scope -> { kept }

  scope :by_year, ->(year) { joins(classrooms_grade: :classroom).where(classrooms: { year: year }) }
  scope :by_unity, ->(unity) { joins(classrooms_grade: :classroom).where(classrooms: { unity_id: unity }) }
  scope :by_grade, ->(grade) { joins(classrooms_grade: :classroom).merge(ClassroomsGrade.by_grade_id(grade)) }
  scope :by_classroom, ->(classroom) { joins(:classrooms_grade).where(classrooms_grades: { classroom_id: classroom }) }
  scope :by_period, ->(period) { where(lessons_boards: { period: period }) }
  scope :by_teacher, ->(teacher_id) do
    joins(lessons_board_lessons: [lessons_board_lesson_weekdays: [:teacher_discipline_classroom]])
      .where(teacher_discipline_classrooms: { teacher_id: teacher_id })
  end
  scope :by_discipline, ->(discipline_id) do
    joins(lessons_board_lessons: [lessons_board_lesson_weekdays: [:teacher_discipline_classroom]])
      .where(teacher_discipline_classrooms: { discipline_id: discipline_id })
  end
  scope :ordered, -> { order(created_at: :desc) }

  after_discard do
    lessons_board_lessons.discard_all
  end

  after_undiscard do
    lessons_board_lessons.undiscard_all
  end
end
