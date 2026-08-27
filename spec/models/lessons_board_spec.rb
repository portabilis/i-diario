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

    def kept_lesson_ids
      LessonsBoardLesson.where(lessons_board_id: lessons_board.id).pluck(:id)
    end

    it 'discards the lessons with the board and brings them back on undiscard' do
      lesson_ids = kept_lesson_ids
      expect(lesson_ids.size).to eq(4)

      lessons_board.discard

      expect(kept_lesson_ids).to be_empty

      # Espelha o caminho real: a reativação chega sobre um registro lido do banco.
      LessonsBoard.with_discarded.find(lessons_board.id).undiscard

      expect(kept_lesson_ids).to match_array(lesson_ids)
    end

    it 'brings back only the lessons of the reactivated board' do
      other_board = create(:lessons_board, :full_lessons_board)
      other_board.discard
      lessons_board.discard

      LessonsBoard.with_discarded.find(lessons_board.id).undiscard

      expect(kept_lesson_ids.size).to eq(4)
      expect(LessonsBoardLesson.where(lessons_board_id: other_board.id)).to be_empty
    end
  end
end
