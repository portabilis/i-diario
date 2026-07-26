require 'rails_helper'

RSpec.describe TransferNote, type: :model do
  let(:current_user) { create(:user) }

  subject do
    create(:transfer_note, :with_teacher_discipline_classroom)
  end

  before do
    current_user.current_classroom_id = subject.classroom_id
    current_user.current_discipline_id = subject.discipline_id
    allow(subject).to receive(:current_user).and_return(current_user)
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:student) }
    it { expect(subject).to belong_to(:teacher) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:discipline_id) }
    it { expect(subject).to validate_presence_of(:student_id) }
    it { expect(subject).to validate_presence_of(:teacher) }
    it { expect(subject).to validate_presence_of(:recorded_at) }
    it { expect(subject).to validate_not_in_future_of(:recorded_at) }
    it { expect(subject).to validate_school_term_day_of(:recorded_at) }

    context 'recorded_at validations' do
      context 'creating a new transfer_note' do
        subject do
          build(:transfer_note, :with_teacher_discipline_classroom)
        end

        context 'when recorded_at is in step range' do
          it { expect(subject.valid?).to be true }
        end

        context 'when recorded_at is out of step range' do
          before do
            subject.recorded_at = subject.step.end_at + 1.day
          end

          it 'requires transfer_note to have a recorded_at in step range' do
            expected_message = I18n.t('errors.messages.not_school_term_day')

            subject.valid?

            expect(subject.errors[:recorded_at]).to include(expected_message)
          end
        end
      end

      context 'updating a existing transfer_note' do
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

            it 'requires transfer_note to have a recorded_at in step range' do
              expected_message = I18n.t('errors.messages.not_school_term_day')

              subject.valid?

              expect(subject.errors[:recorded_at]).to include(expected_message)
            end
          end
        end
      end
    end

    context 'uniqueness per student, classroom, discipline and step' do
      let!(:existing) { create(:transfer_note, :with_teacher_discipline_classroom) }

      subject do
        build(
          :transfer_note,
          classroom: existing.classroom,
          discipline: existing.discipline,
          student: existing.student,
          teacher: existing.teacher,
          step_number: existing.step_number,
          recorded_at: existing.recorded_at
        )
      end

      it 'is invalid when another transfer note already exists for the same scope' do
        expected_message = I18n.t(
          'activerecord.errors.models.transfer_note.attributes.base.transfer_note_already_exists'
        )

        expect(subject.valid?).to be false
        expect(subject.errors[:base]).to include(expected_message)
      end

      it 'allows a transfer note for the same student in a different step' do
        subject.step_number = existing.step_number + 1

        subject.valid?

        expect(subject.errors[:base]).to_not include(
          I18n.t('activerecord.errors.models.transfer_note.attributes.base.transfer_note_already_exists')
        )
      end
    end
  end
end
