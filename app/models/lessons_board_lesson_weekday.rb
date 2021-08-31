class LessonsBoardLessonWeekday < ActiveRecord::Base
  include Discardable

  audited

  has_enumeration_for :weekday, with: Workdays

  belongs_to :teacher_discipline_classroom
  belongs_to :lessons_board_lesson

  default_scope -> { kept }
end
