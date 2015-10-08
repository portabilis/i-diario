require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlan, type: :model do
  subject { FactoryGirl.build(:knowledge_area_lesson_plan) }

  describe 'associations' do
    it { expect(subject).to belong_to(:lesson_plan) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:lesson_plan) }

    it 'should validate uniqueness of knowledge area lesson plan' do
      another_lesson_plan = FactoryGirl.create(
        :lesson_plan,
        lesson_plan_date: '30/06/2020'
      )
      another_knowledge_area_lesson_plan = FactoryGirl.create(
        :knowledge_area_lesson_plan,
        lesson_plan: another_lesson_plan
      )

      lesson_plan = FactoryGirl.create(
        :lesson_plan,
        school_calendar: another_lesson_plan.school_calendar,
        classroom: another_lesson_plan.classroom,
        lesson_plan_date: '30/06/2020'
      )
      subject = FactoryGirl.build(
        :knowledge_area_lesson_plan,
        lesson_plan: lesson_plan
      )

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:lesson_plan]).to include('já existe um plano de aula para a aula informada')
      expect(subject.lesson_plan.errors.messages[:lesson_plan_date]).to include('já existe um plano de aula para a aula informada')
    end
  end
end
