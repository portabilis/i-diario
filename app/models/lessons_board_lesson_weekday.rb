class LessonsBoardLessonWeekday < ActiveRecord::Base
  include Discardable

  audited

  validates :teacher_discipline_classroom_id, presence: true

  belongs_to :teacher_discipline_classroom
  belongs_to :lessons_board_lesson

  default_scope -> { kept }
end
