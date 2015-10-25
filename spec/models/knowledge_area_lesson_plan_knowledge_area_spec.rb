require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlanKnowledgeArea, type: :model do
  describe 'associations' do
    it { expect(subject).to belong_to(:knowledge_area_lesson_plan) }
    it { expect(subject).to belong_to(:knowledge_area) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:knowledge_area_lesson_plan) }
    it { expect(subject).to validate_presence_of(:knowledge_area) }
  end
end
