require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlan, type: :model do
  subject { FactoryGirl.build(:knowledge_area_lesson_plan) }

  describe 'associations' do
    it { expect(subject).to belong_to(:lesson_plan) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:lesson_plan) }
  end
end
