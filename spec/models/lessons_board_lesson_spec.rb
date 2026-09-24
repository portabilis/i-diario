require 'rails_helper'

RSpec.describe LessonsBoardLesson, type: :model do
  subject {
    build(
      :lessons_board_lesson
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:lessons_board) }
  end

  describe 'discard and undiscard cascade' do
    let(:lessons_board_lesson) { create(:lessons_board_lesson, :with_five_weekdays) }

    def kept_weekdays_count
      LessonsBoardLessonWeekday.where(lessons_board_lesson_id: lessons_board_lesson.id).count
    end

    it 'discards the weekdays with the lesson and brings them back on undiscard' do
      expect(kept_weekdays_count).to eq(5)

      lessons_board_lesson.discard

      expect(kept_weekdays_count).to eq(0)

      # Espelha o caminho real: a reativação chega sobre um registro lido do banco.
      LessonsBoardLesson.with_discarded.find(lessons_board_lesson.id).undiscard

      expect(kept_weekdays_count).to eq(5)
    end

    it 'keeps a weekday that had been removed before the lesson was discarded' do
      removed_weekday = lessons_board_lesson.lessons_board_lesson_weekdays.find_by(weekday: :friday)
      # Slot que saiu do horário antes do descarte da aula — não volta com ela.
      removed_weekday.discard
      removed_weekday.update_columns(discarded_at: 10.days.ago)

      lessons_board_lesson.discard
      LessonsBoardLesson.with_discarded.find(lessons_board_lesson.id).undiscard

      expect(kept_weekdays_count).to eq(4)
      expect(LessonsBoardLessonWeekday.with_discarded.find(removed_weekday.id)).to be_discarded
    end
  end
end
