require 'rails_helper'

RSpec.describe KnowledgeAreaTeachingPlan, type: :model do
  subject {
    build(
      :knowledge_area_teaching_plan,
      :with_teacher_discipline_classroom
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:teaching_plan) }
    it { expect(subject).to have_many(:knowledge_area_teaching_plan_knowledge_areas).dependent(:destroy) }
    it { expect(subject).to have_many(:knowledge_areas).through(:knowledge_area_teaching_plan_knowledge_areas) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:teaching_plan) }
    it { expect(subject).to validate_presence_of(:knowledge_area_ids) }

    it 'should validate uniqueness of knowledge area teaching plan' do
      knowledge_area = create(:knowledge_area)

      another_knowledge_area_teaching_plan = create(
        :knowledge_area_teaching_plan,
        :with_teacher_discipline_classroom,
        knowledge_area_ids: knowledge_area.id
      )

      teaching_plan = create(
        :teaching_plan,
        year: another_knowledge_area_teaching_plan.teaching_plan.year,
        unity: another_knowledge_area_teaching_plan.teaching_plan.unity,
        grade: another_knowledge_area_teaching_plan.teaching_plan.grade,
        school_term: another_knowledge_area_teaching_plan.teaching_plan.school_term,
        teacher: another_knowledge_area_teaching_plan.teaching_plan.teacher
      )
      subject = build(
        :knowledge_area_teaching_plan,
        teaching_plan: teaching_plan,
        knowledge_area_ids: knowledge_area.id
      )

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:base]).to include('Já existe um plano de ensino para o período informado')
    end
  end
end
