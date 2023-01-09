class LessonsBoardLessonWeekday < ApplicationRecord
  include Audit
  include Discardable

  audited

  belongs_to :teacher_discipline_classroom
  belongs_to :lessons_board_lesson

  default_scope -> { kept }

  scope :by_classroom, ->(classroom_id) do
    joins(:teacher_discipline_classroom)
      .where(teacher_discipline_classrooms: { classroom_id: classroom_id })
  end

  scope :by_teacher, ->(teacher_id) do
    joins(:teacher_discipline_classroom)
      .where(teacher_discipline_classrooms: { teacher_id: teacher_id })
  end
  scope :by_teacher_discipline_classroom, ->(teacher_discipline_classroom_id) do
    where(teacher_discipline_classroom_id:
            teacher_discipline_classroom_id)
  end
  scope :by_discipline, ->(discipline_id) do
    joins(teacher_discipline_classroom: [:discipline])
      .where(disciplines: { id: discipline_id })
  end
  scope :by_weekday, ->(weekday) { where(weekday:  weekday) }

  scope :by_period, ->(period) do
    joins(lessons_board_lesson: [:lessons_board])
      .where(lessons_boards: { period: period })
  end
end
