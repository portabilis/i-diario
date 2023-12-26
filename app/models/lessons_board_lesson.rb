class LessonsBoardLesson < ActiveRecord::Base
  include Audit
  include Discardable

  audited

  belongs_to :lessons_board
  has_many :lessons_board_lesson_weekdays

  accepts_nested_attributes_for :lessons_board_lesson_weekdays, allow_destroy: true

  default_scope -> { kept }

  after_discard do
    lessons_board_lesson_weekdays.discard_all
  end

  after_undiscard do
    lessons_board_lesson_weekdays.undiscard_all
  end
end
