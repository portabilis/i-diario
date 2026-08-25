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

  # Dia da semana também é descartado isoladamente, quando o horário deixa de ter aquele slot.
  # Esse não volta junto com a aula.
  after_undiscard do
    undiscard_dependents_discarded_with(lessons_board_lesson_weekdays)
  end
end
