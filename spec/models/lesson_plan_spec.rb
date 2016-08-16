require 'rails_helper'

RSpec.describe LessonPlan, type: :model do
  subject { FactoryGirl.build(:lesson_plan) }

  describe 'associations' do
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to have_and_belong_to_many(:contents) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }

    it "should validate if there is at least one content assigned" do
      subject = FactoryGirl.build(:lesson_plan_without_contents)

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:contents]).to include("Deve possuir pelo menos 1 conteúdo")
    end
  end
end
