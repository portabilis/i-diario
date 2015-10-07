require 'rails_helper'

RSpec.describe LessonPlan, type: :model do
  subject { FactoryGirl.build(:lesson_plan) }

  describe 'associations' do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:lesson_plan_date) }
    it { expect(subject).to validate_presence_of(:contents) }
  end
end
