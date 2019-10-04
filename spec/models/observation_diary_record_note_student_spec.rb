require 'rails_helper'

RSpec.describe ObservationDiaryRecordNoteStudent do
  let(:discipline) { create(:discipline) }
  let(:teacher) { create(:teacher) }
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps,
      :with_teacher_discipline_classroom,
      :by_discipline,
      discipline: discipline,
      teacher: teacher
    )
  }
  let(:school_calendar) { classroom.calendar.school_calendar }
  let(:observation_diary_record) do
    create(
      :observation_diary_record,
      :with_notes,
      school_calendar: school_calendar,
      classroom: classroom,
      discipline: discipline,
      teacher: teacher,
      date: Date.current - 1.day
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
        :observation_diary_record,
        :with_notes,
        school_calendar: school_calendar,
        classroom: classroom,
        discipline: discipline,
        teacher: teacher,
        date: Date.current
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
