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

  # A sincronização do quadro de aulas também descarta dias da semana um a um, quando o slot
  # some do i-Educar — esses não podem voltar junto com a aula.
  after_undiscard do
    undiscard_dependents_discarded_with(lessons_board_lesson_weekdays)
  end
end
