require 'rails_helper'

RSpec.describe SchoolTermRecoveryDiaryRecord, type: :model do
  let(:current_user) { create(:user) }

  subject(:school_term_recovery_diary_record) { build(:school_term_recovery_diary_record) }

  before do
    current_user.current_classroom_id = subject.classroom_id
    current_user.current_discipline_id = subject.discipline_id
    allow(subject.recovery_diary_record).to receive(:current_user).and_return(current_user)
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record) }
  end

  describe 'validations' do
    it 'should validate uniqueness of school term recovery diary record' do
      classroom = create(
        :classroom,
        :with_classroom_semester_steps,
        :score_type_numeric_and_concept_create_rule
      )
      another_recovery_diary_record = create(
        :recovery_diary_record,
        :with_teacher_discipline_classroom,
        :with_students,
        classroom: classroom
      )

      current_user.current_classroom_id = another_recovery_diary_record.classroom_id
      current_user.current_discipline_id = another_recovery_diary_record.discipline_id

      another_recovery_diary_record.current_user = current_user

      another_school_term_recovery_diary_record = create(
        :school_term_recovery_diary_record,
        recovery_diary_record: another_recovery_diary_record
      )
      recovery_diary_record = build(
        :recovery_diary_record,
        :with_teacher_discipline_classroom,
        :with_students,
        unity: another_recovery_diary_record.unity,
        classroom: classroom,
        discipline: another_recovery_diary_record.discipline
      )
      subject = build(
        :school_term_recovery_diary_record,
        recovery_diary_record: recovery_diary_record,
        step: another_school_term_recovery_diary_record.step
      )

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:step_id]).to include(
        I18n.t(
          :uniqueness_of_school_term_recovery_diary_record,
          scope: [
            :activerecord, :errors, :models, :school_term_recovery_diary_record, :attributes, :step_id
          ]
        )
      )
    end

    context 'recorded_at validations' do
      context 'creating a new school_term_recovery_diary_record' do
        subject { build(:school_term_recovery_diary_record) }

        context 'when recorded_at is in step range' do
          it { expect(subject.valid?).to be true }
        end

        context 'when recorded_at is out of step range' do
          before do
            subject.recorded_at = subject.step.end_at + 1.day
          end

          it 'requires school_term_recovery_diary_record to have a recorded_at in step range' do
            expected_message = I18n.t('errors.messages.not_school_term_day')

            subject.valid?

            expect(subject.errors[:recorded_at]).to include(expected_message)
          end
        end
      end

      context 'updating a existing school_term_recovery_diary_record' do
        context 'when recorded_at is out of step range' do
          context 'recorded_at has not changed' do
            before do
              subject.recorded_at = subject.step.end_at + 3.day
              subject.save!(validate: false)
            end

            it 'school_term_recovery_diary_record is valid to save' do
              Timecop.freeze(subject.recorded_at) do
                expect(subject.valid?).to be true
              end
            end
          end

          context 'recorded_at has changed' do
            before do
              subject.recorded_at = subject.step.end_at + 1.day
            end

            it 'requires school_term_recovery_diary_record to have a recorded_at in step range' do
              expected_message = I18n.t('errors.messages.not_school_term_day')

              subject.valid?

              expect(subject.errors[:recorded_at]).to include(expected_message)
            end
          end
        end
      end
    end
  end
end
