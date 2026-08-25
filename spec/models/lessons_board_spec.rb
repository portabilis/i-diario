require 'rails_helper'

RSpec.describe LessonsBoard, type: :model do
  subject {
    build(
      :lessons_board
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:classrooms_grade) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:period) }
    it { expect(subject).to validate_presence_of(:classrooms_grade_id) }
  end

  describe 'discard and undiscard cascade' do
    let(:lessons_board) { create(:lessons_board, :full_lessons_board) }

    def kept_lessons_count
      LessonsBoardLesson.where(lessons_board_id: lessons_board.id).count
    end

    it 'discards the lessons with the board and brings them back on undiscard' do
      expect(kept_lessons_count).to eq(4)

      lessons_board.discard

      expect(kept_lessons_count).to eq(0)

      # Recarregado de propósito: a reativação chega sobre um registro novo, e só assim a
      # associação filtrada por `kept` entra em jogo.
      LessonsBoard.with_discarded.find(lessons_board.id).undiscard

      expect(kept_lessons_count).to eq(4)
    end
  end
end
