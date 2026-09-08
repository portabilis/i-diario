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

  describe 'uniqueness of classrooms grade and period' do
    let(:classrooms_grade) { create(:classrooms_grade) }
    let!(:existing_board) do
      create(:lessons_board, classrooms_grade: classrooms_grade, period: Periods::MATUTINAL)
    end

    it 'rejects another board for the same classrooms grade and period' do
      duplicated = build(:lessons_board, classrooms_grade: classrooms_grade, period: Periods::MATUTINAL)

      expect(duplicated).to_not be_valid
      expect(duplicated.errors.details[:classrooms_grade_id]).to eq(
        [{ error: :uniqueness_of_classrooms_grade_and_period }]
      )
    end

    it 'accepts another board for the same classrooms grade on a different period' do
      # Turma de período integral tem um quadro de aulas por turno.
      other_period = build(:lessons_board, classrooms_grade: classrooms_grade, period: Periods::VESPERTINE)

      expect(other_period).to be_valid
    end

    it 'accepts another board for the same classroom on a different grade' do
      # Multisseriada: cada série da turma tem o próprio quadro no mesmo turno.
      other_grade = create(:classrooms_grade, classroom: classrooms_grade.classroom)
      other_board = build(:lessons_board, classrooms_grade: other_grade, period: Periods::MATUTINAL)

      expect(other_board).to be_valid
    end

    it 'accepts a new board when the existing one is discarded' do
      existing_board.discard

      recreated = build(:lessons_board, classrooms_grade: classrooms_grade, period: Periods::MATUTINAL)

      expect(recreated).to be_valid
    end

    it 'accepts saving the persisted board again' do
      expect(existing_board).to be_valid
    end

    it 'rejects moving a board to a period already taken' do
      moved = create(:lessons_board, classrooms_grade: classrooms_grade, period: Periods::VESPERTINE)
      moved.period = Periods::MATUTINAL

      expect(moved).to_not be_valid
    end
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
