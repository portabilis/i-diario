require 'rails_helper'

RSpec.describe SchoolTermRecoveryDiaryRecord, type: :model do
  subject(:school_term_recovery_diary_record) { build(:school_term_recovery_diary_record) }

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record).dependent(:destroy) }
    it { expect(subject).to belong_to(:school_calendar_step) }
  end

# FIXME
#   describe 'validations' do
#     it { expect(subject).to validate_presence_of(:recovery_diary_record) }
#
#     it 'should validate uniqueness of school term recovery diary record' do
#       test_setting = create(:test_setting, year: 2015)
#       exam_rule = create(:exam_rule, recovery_type: RecoveryTypes::PARALLEL)
#       classroom = create(:classroom, exam_rule: exam_rule)
#       another_recovery_diary_record = build(
#         :recovery_diary_record_with_students,
#         classroom: classroom
#       )
#       another_school_term_recovery_diary_record = build(
#         :school_term_recovery_diary_record,
#         recovery_diary_record: another_recovery_diary_record
#       )
#       another_school_term_recovery_diary_record.save
#
#       recovery_diary_record = build(:recovery_diary_record_with_students,
#         unity: another_school_term_recovery_diary_record.recovery_diary_record.unity,
#         classroom: classroom,
#         discipline: another_school_term_recovery_diary_record.recovery_diary_record.discipline
#       )
#       subject = build(
#         :school_term_recovery_diary_record,
#         recovery_diary_record: recovery_diary_record,
#         school_calendar_step: another_school_term_recovery_diary_record.school_calendar_step
#       )
#
#       expect(subject).to_not be_valid
#       expect(subject.errors.messages[:school_calendar_step]).to include('já existe um lançamento recuperação para a etapa informada')
#     end
#   end
end
