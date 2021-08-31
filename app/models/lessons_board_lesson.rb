class LessonsBoardLesson < ActiveRecord::Base
  include Discardable

  audited

  belongs_to :lessons_board
  has_many :lessons_board_lesson_weekdays, dependent: :restrict_with_error

  attr_accessor :teacher, :lesson_number

  accepts_nested_attributes_for :lessons_board_lesson_weekdays, allow_destroy: false

  default_scope -> { kept }
end
