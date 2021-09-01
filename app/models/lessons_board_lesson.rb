class LessonsBoardLesson < ActiveRecord::Base
  include Discardable

  audited

  belongs_to :lessons_board
  has_many :lessons_board_lesson_weekdays, dependent: :destroy

  accepts_nested_attributes_for :lessons_board_lesson_weekdays, allow_destroy: true

  default_scope -> { kept }
end
