require 'rails_helper'

RSpec.describe ComplementaryExam, type: :model do
  let(:current_user) { create(:user) }

  subject do
    create(
      :complementary_exam,
      :with_teacher_discipline_classroom
    )
  end

  before do
    current_user.current_classroom_id = subject.classroom_id
    current_user.current_discipline_id = subject.discipline_id
    allow(subject).to receive(:current_user).and_return(current_user)
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:complementary_exam_setting) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:discipline) }
    it { expect(subject).to validate_presence_of(:complementary_exam_setting) }
    it { expect(subject).to validate_presence_of(:recorded_at) }
    it { expect(subject).to validate_not_in_future_of(:recorded_at) }
    it { expect(subject).to validate_school_term_day_of(:recorded_at) }

    it 'should validate the year of recorded_at is the same as the year of the settings of the exam' do
      expect(subject.complementary_exam_setting.year).to eq(subject.recorded_at.year)
    end

    context 'recorded_at validations' do
      context 'creating a new complementary_exam' do
        subject do
          build(
            :complementary_exam,
            :with_teacher_discipline_classroom
          )
        end

        context 'when recorded_at is in step range' do
          it { expect(subject.valid?).to be true }
        end

        context 'when recorded_at is out of step range' do
          before do
            subject.recorded_at = subject.step.end_at + 1.day
          end

          it 'requires complementary_exam to have a recorded_at in step range' do
            expected_message = I18n.t('errors.messages.not_school_term_day')

            subject.valid?

            expect(subject.errors[:recorded_at]).to include(expected_message)
          end
        end
      end

      context 'updating a existing complementary_exam' do
        context 'when recorded_at is out of step range' do
          context 'recorded_at has not changed' do
            before do
              subject.recorded_at = subject.step.end_at + 1.day
              subject.save!(validate: false)
            end

            it { expect(subject.valid?).to be true }
          end

          context 'recorded_at has changed' do
            before do
              subject.recorded_at = subject.step.end_at + 1.day
            end

            it 'requires complementary_exam to have a recorded_at in step range' do
              expected_message = I18n.t('errors.messages.not_school_term_day')

              subject.valid?

              expect(subject.errors[:recorded_at]).to include(expected_message)
            end
          end
        end
      end
    end
  end

  # A lista do diário traz uma linha por matrícula; a nota é uma por aluno.
  describe '#students_attributes=' do
    let(:student) { create(:student) }

    def rows_of(exam, student_id)
      exam.students.select { |exam_student| exam_student.student_id == student_id }
    end

    context 'with a new exam' do
      subject(:complementary_exam) { build(:complementary_exam, :with_teacher_discipline_classroom) }

      it 'does not build the row of an enrollment that is not in the classroom on the date' do
        complementary_exam.students_attributes = {
          '0' => { student_id: student.id, score: '', active: 'false' },
          '1' => { student_id: student.id, score: '', active: 'false' }
        }

        expect(rows_of(complementary_exam, student.id)).to eq([])
      end

      it 'builds the row of the enrollment that is in the classroom on the date' do
        complementary_exam.students_attributes = {
          '0' => { student_id: student.id, score: '', active: 'false' },
          '1' => { student_id: student.id, score: '2', active: 'true' }
        }

        expect(rows_of(complementary_exam, student.id).map(&:score)).to eq([2])
      end

      it 'builds a single row, the one with score, when two enrollments are in the classroom on the date' do
        complementary_exam.students_attributes = {
          '0' => { student_id: student.id, score: '', active: 'true' },
          '1' => { student_id: student.id, score: '2', active: 'true' }
        }

        expect(rows_of(complementary_exam, student.id).map(&:score)).to eq([2])
      end

      it 'builds a single row when the two active rows of the student are blank' do
        complementary_exam.students_attributes = {
          '0' => { student_id: student.id, score: '', active: 'true' },
          '1' => { student_id: student.id, score: '', active: 'true' }
        }

        expect(rows_of(complementary_exam, student.id).size).to eq(1)
      end
    end

    context 'with a saved exam' do
      subject(:complementary_exam) { create(:complementary_exam, :with_teacher_discipline_classroom) }

      let(:exam_student) { complementary_exam.students.first }

      it 'keeps the saved record instead of a new active row of the same student' do
        complementary_exam.students_attributes = {
          '0' => { student_id: exam_student.student_id, score: '2', active: 'true' },
          '1' => { id: exam_student.id, student_id: exam_student.student_id, score: '3', active: 'true' }
        }

        rows = rows_of(complementary_exam, exam_student.student_id)

        expect(rows.map(&:id)).to eq([exam_student.id])
        expect(rows.map(&:score)).to eq([3])
      end

      it 'destroys the saved record marked for destruction even when its row is not active' do
        complementary_exam.students_attributes = { '0' => { id: exam_student.id, _destroy: '1', active: '' } }

        expect(rows_of(complementary_exam, exam_student.student_id).map(&:marked_for_destruction?)).to eq([true])
      end
    end
  end
end
