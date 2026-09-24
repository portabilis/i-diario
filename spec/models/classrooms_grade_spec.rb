require 'rails_helper'

RSpec.describe ClassroomsGrade, type: :model do
  describe 'attributes' do
    it { expect(subject).to respond_to(:classroom_id) }
    it { expect(subject).to respond_to(:grade_id) }
    it { expect(subject).to respond_to(:exam_rule_id) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:grade) }
    it { expect(subject).to belong_to(:exam_rule) }
    it { expect(subject).to have_many(:student_enrollment_classrooms) }
    it { expect(subject).to have_many(:lessons_boards) }
  end

  describe 'undiscard cascade' do
    let(:classrooms_grade) { create(:classrooms_grade) }

    # Espelha o caminho real: a reativação chega pela sincronização, sobre um registro lido do
    # banco — nunca sobre o mesmo objeto que fez o descarte.
    def undiscard_from_a_fresh_record
      ClassroomsGrade.with_discarded.find(classrooms_grade.id).undiscard
    end

    context 'when the lessons board was discarded along with the grade link' do
      let!(:lessons_board) { create(:lessons_board, classrooms_grade: classrooms_grade) }

      before { classrooms_grade.discard }

      it 'brings the lessons board back' do
        expect(LessonsBoard.with_discarded.find(lessons_board.id)).to be_discarded

        undiscard_from_a_fresh_record

        expect(LessonsBoard.with_discarded.find(lessons_board.id)).to be_kept
      end
    end

    context 'when the classroom has one lessons board per period' do
      let!(:morning_board) do
        create(:lessons_board, classrooms_grade: classrooms_grade, period: Periods::MATUTINAL)
      end
      let!(:afternoon_board) do
        create(:lessons_board, classrooms_grade: classrooms_grade, period: Periods::VESPERTINE)
      end

      it 'discards and brings back every board of the grade link' do
        classrooms_grade.discard

        expect(LessonsBoard.where(classrooms_grade_id: classrooms_grade.id)).to be_empty

        undiscard_from_a_fresh_record

        expect(LessonsBoard.where(classrooms_grade_id: classrooms_grade.id).pluck(:id))
          .to contain_exactly(morning_board.id, afternoon_board.id)
      end
    end

    context 'when the lessons board had already been deleted by the user' do
      let!(:lessons_board) { create(:lessons_board, classrooms_grade: classrooms_grade) }

      before do
        # Exclusão completa e anterior ao descarte do vínculo — o `discard` primeiro deixa a
        # árvore do quadro consistente, e só então a data é recuada.
        lessons_board.discard
        lessons_board.update_columns(discarded_at: 10.days.ago)
        classrooms_grade.discard
      end

      it 'keeps the lessons board deleted' do
        undiscard_from_a_fresh_record

        expect(LessonsBoard.with_discarded.find(lessons_board.id)).to be_discarded
      end
    end

    context 'when the grade link had student enrollments' do
      let!(:student_enrollment_classroom) do
        create(:student_enrollment_classroom, classrooms_grade: classrooms_grade)
      end

      before { classrooms_grade.discard }

      it 'brings the enrollments back' do
        undiscard_from_a_fresh_record

        expect(
          StudentEnrollmentClassroom.with_discarded.find(student_enrollment_classroom.id)
        ).to be_kept
      end
    end

    context 'when another grade link has discarded dependents of its own' do
      let!(:lessons_board) { create(:lessons_board, classrooms_grade: classrooms_grade) }
      let(:other_classrooms_grade) { create(:classrooms_grade) }
      let!(:other_lessons_board) do
        create(:lessons_board, classrooms_grade: other_classrooms_grade)
      end

      before do
        other_classrooms_grade.discard
        classrooms_grade.discard
      end

      it 'brings back only the dependents of the reactivated grade link' do
        undiscard_from_a_fresh_record

        expect(LessonsBoard.with_discarded.find(lessons_board.id)).to be_kept
        expect(LessonsBoard.with_discarded.find(other_lessons_board.id)).to be_discarded
      end
    end
  end
end
