require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlan, type: :model do
  subject { create(:knowledge_area_lesson_plan, :with_teacher_discipline_classroom) }

  describe 'associations' do
    it { expect(subject).to belong_to(:lesson_plan) }
    it { expect(subject).to have_many(:knowledge_area_lesson_plan_knowledge_areas).dependent(:destroy) }
    it { expect(subject).to have_many(:knowledge_areas).through(:knowledge_area_lesson_plan_knowledge_areas) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:lesson_plan) }

    it 'should allow more than one knowledge area lesson plan in the same date' do
      discipline = create(:discipline)
      knowledge_area_lesson_plan = create(
        :knowledge_area_lesson_plan,
        :with_teacher_discipline_classroom,
        knowledge_area_ids: discipline.knowledge_area.id
      )

      lesson_plan = create(
        :lesson_plan,
        :with_teacher_discipline_classroom,
        classroom: knowledge_area_lesson_plan.lesson_plan.classroom,
        discipline: discipline
      )
      subject = build(
        :knowledge_area_lesson_plan,
        knowledge_area_ids: discipline.knowledge_area.id,
        lesson_plan: lesson_plan,
        teacher_id: lesson_plan.teacher_id
      )

      expect(subject).to be_valid
      expect(subject.errors[:knowledge_area_ids].any?).to be(false)
    end
  end
end
