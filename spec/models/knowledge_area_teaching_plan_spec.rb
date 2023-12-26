require 'rails_helper'

RSpec.describe KnowledgeAreaTeachingPlan, type: :model do
  subject {
    build(
      :knowledge_area_teaching_plan,
      :with_teacher_discipline_classroom
    )
  }

  before do
    allow_any_instance_of(TeachingPlan).to receive(:yearly?).and_return(true)
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:teaching_plan) }
    it { expect(subject).to have_many(:knowledge_area_teaching_plan_knowledge_areas).dependent(:destroy) }
    it { expect(subject).to have_many(:knowledge_areas).through(:knowledge_area_teaching_plan_knowledge_areas) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:teaching_plan) }
    it { expect(subject).to validate_presence_of(:knowledge_area_ids) }
  end
end
