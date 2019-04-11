require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlan, type: :model do
  subject { FactoryGirl.build(:knowledge_area_lesson_plan) }

  describe 'associations' do
    it { expect(subject).to belong_to(:lesson_plan) }
    it { expect(subject).to have_many(:knowledge_area_lesson_plan_knowledge_areas).dependent(:destroy) }
    it { expect(subject).to have_many(:knowledge_areas).through(:knowledge_area_lesson_plan_knowledge_areas) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:lesson_plan) }

    it 'should allow more than one knowledge area lesson plan in the same date' do
      knowledge_area = FactoryGirl.create(:knowledge_area)
      another_lesson_plan = FactoryGirl.create(
        :lesson_plan,
        start_at: '30/06/2020',
        end_at: '07/07/2020'
      )
      another_knowledge_area_lesson_plan = FactoryGirl.create(
        :knowledge_area_lesson_plan,
        knowledge_area_ids: knowledge_area.id,
        lesson_plan: another_lesson_plan
      )

      lesson_plan = FactoryGirl.create(
        :lesson_plan,
        school_calendar: another_lesson_plan.school_calendar,
        classroom: another_lesson_plan.classroom,
        start_at: '06/07/2020',
        end_at: '30/07/2020'
      )
      subject = FactoryGirl.build(
        :knowledge_area_lesson_plan,
        knowledge_area_ids: knowledge_area.id,
        lesson_plan: lesson_plan
      )

      expect(subject).to be_valid
      expect(subject.errors[:knowledge_area_ids].any?).to be(false)
    end
  end
end
