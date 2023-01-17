require 'rails_helper'

RSpec.describe ObservationDiaryRecordNote do
  let(:classroom) { create(:classroom, :with_classroom_semester_steps, :by_discipline) }
  let(:observation_diary_record) {
    create(
      :observation_diary_record,
      :with_teacher_discipline_classroom,
      :with_notes,
      classroom: classroom
    )
  }

  subject { build(:observation_diary_record_note, observation_diary_record: observation_diary_record) }

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
