require 'rails_helper'

RSpec.describe FinalRecoveryDiaryRecord, type: :model do
  subject(:final_recovery_diary_record) { build(:final_recovery_diary_record) }

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record).dependent(:destroy) }
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:recovery_diary_record) }
    it { expect(subject).to validate_presence_of(:school_calendar) }

    it 'validates uniqueness per school_calendar, classroom and discipline' do
      another_final_recovery_diary_record = create(:final_recovery_diary_record)
      recovery_diary_record = build(
        :recovery_diary_record_with_students,
        classroom: another_final_recovery_diary_record.recovery_diary_record.classroom,
        discipline: another_final_recovery_diary_record.recovery_diary_record.discipline,
      )
      subject = build(
        :final_recovery_diary_record,
        school_calendar: another_final_recovery_diary_record.school_calendar,
        recovery_diary_record: recovery_diary_record
      )

      expect(subject).to_not be_valid
      expect(subject.errors[:year]).to include('já existe um lançamento recuperação para este ano')
    end
  end
end
