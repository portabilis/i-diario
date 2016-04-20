require 'rails_helper'

RSpec.describe ObservationDiaryRecord do
  let(:school_calendar) { create(:school_calendar_with_one_step, year: 2015) }
  let(:exam_rule) { create(:exam_rule, frequency_type: FrequencyTypes::BY_DISCIPLINE) }
  let(:classroom) { create(:classroom, exam_rule: exam_rule) }
  subject do
    build(
      :observation_diary_record_with_notes,
      school_calendar: school_calendar,
      classroom: classroom,
      date: '17/03/2015'
    )
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:teacher) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to have_many(:notes).dependent(:destroy) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:teacher) }
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:date) }
    it { expect(subject).to validate_not_in_future_of(:date) }
    it { expect(subject).to validate_school_calendar_day_of(:date) }
    it { expect(subject).to validate_presence_of(:notes) }

    it 'should require unique value for date scoped to school_calendar_id, ' \
       'teacher_id, classroom_id, discipline_id' do
      create(
        :observation_diary_record_with_notes,
        school_calendar: school_calendar,
        classroom: classroom,
        date: '17/03/2015'
      )

      expect(subject).to(
        validate_uniqueness_of(:date).scoped_to(
          :school_calendar_id,
          :teacher_id,
          :classroom_id,
          :discipline_id
        )
      )
    end
  end
end
