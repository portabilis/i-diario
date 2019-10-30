require 'rails_helper'

RSpec.describe ObservationDiaryRecord do
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps,
      :by_discipline
    )
  }

  subject {
    create(
      :observation_diary_record,
      :with_teacher_discipline_classroom,
      :with_notes,
      classroom: classroom
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:teacher) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to have_many(:notes).dependent(:destroy) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:date) }
    it { expect(subject).to validate_not_in_future_of(:date) }
    it { expect(subject).to validate_school_calendar_day_of(:date) }
    it { expect(subject).to validate_presence_of(:notes) }

    it 'should require unique value for date scoped to school_calendar_id, ' \
       'teacher_id, classroom_id, discipline_id' do
      observation_diary_record = build(
        :observation_diary_record,
        :with_notes,
        classroom: classroom,
        teacher: subject.teacher,
        discipline: subject.discipline
      )

      expect(observation_diary_record).to_not be_valid
      expect(observation_diary_record.errors[:date]).to include('já está em uso')
    end
  end
end
