require 'rails_helper'

RSpec.describe ObservationDiaryRecordNoteStudent do
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
  let(:observation_diary_record_note) do
    build(
      :observation_diary_record_note,
      observation_diary_record: observation_diary_record
    )
  end

  subject do
    build(
      :observation_diary_record_note_student,
      observation_diary_record_note: observation_diary_record_note
    )
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:observation_diary_record_note) }
    it { expect(subject).to belong_to(:student) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:observation_diary_record_note) }
    it { expect(subject).to validate_presence_of(:student) }

    it 'should require unique value for student scoped to observation_diary_record_note_id' do
      observation_diary_record = create(
        :observation_diary_record_with_notes,
        school_calendar: school_calendar,
        classroom: classroom,
        date: '18/03/2015'
      )
      observation_diary_record_note = build(
        :observation_diary_record_note,
        observation_diary_record: observation_diary_record
      )

      create(
        :observation_diary_record_note_student,
        observation_diary_record_note: observation_diary_record_note
      )
      
      expect(subject).to validate_uniqueness_of(:student).scoped_to(:observation_diary_record_note_id)
    end
  end
end
