require 'rails_helper'

RSpec.describe ObservationDiaryRecordNote do
  let(:school_calendar) { create(:school_calendar_with_one_step, year: 2015) }
  let(:exam_rule) { create(:exam_rule, frequency_type: FrequencyTypes::BY_DISCIPLINE) }
  let(:classroom) { create(:classroom, exam_rule: exam_rule) }
  let(:observation_diary_record) do
    create(
      :observation_diary_record_with_notes,
      school_calendar: school_calendar,
      classroom: classroom,
      date: '17/03/2015'
    )
  end

  subject do
    build(
      :observation_diary_record_note,
      observation_diary_record: observation_diary_record
    )
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:observation_diary_record) }
    it { expect(subject).to have_many(:note_students).dependent(:destroy) }
    it { expect(subject).to have_many(:students).through(:note_students) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:observation_diary_record) }
    it { expect(subject).to validate_presence_of(:description) }
  end
end
