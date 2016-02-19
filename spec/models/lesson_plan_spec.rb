require 'rails_helper'

RSpec.describe LessonPlan, type: :model do
  subject { FactoryGirl.build(:lesson_plan) }

  describe 'associations' do
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }
    it { expect(subject).to validate_presence_of(:contents) }
  end
end
