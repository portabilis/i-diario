require 'rails_helper'

RSpec.describe DisciplineLessonPlan, type: :model do
  subject { FactoryGirl.build(:discipline_lesson_plan) }

  describe 'associations' do
    it { expect(subject).to belong_to(:lesson_plan) }
    it { expect(subject).to belong_to(:discipline) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:lesson_plan) }
    it { expect(subject).to validate_presence_of(:discipline) }

    context 'when classroom frequency type is by discipline' do
      it 'should require classes to be set' do
        exam_rule = FactoryGirl.create(:exam_rule, frequency_type: FrequencyTypes::BY_DISCIPLINE)
        classroom = FactoryGirl.create(:classroom, exam_rule: exam_rule)
        lesson_plan = FactoryGirl.create(:lesson_plan, lesson_plan_date: '30/06/2020', classroom: classroom)

        subject = FactoryGirl.build(:discipline_lesson_plan, lesson_plan: lesson_plan)

        expect(subject).to validate_presence_of(:classes)
      end
    end

    context 'when classroom frequency type is general' do
      it 'should not require classes to be set' do
        exam_rule = FactoryGirl.create(:exam_rule, frequency_type: FrequencyTypes::GENERAL)
        classroom = FactoryGirl.create(:classroom, exam_rule: exam_rule)
        lesson_plan = FactoryGirl.create(:lesson_plan, lesson_plan_date: '30/06/2020', classroom: classroom)

        subject = FactoryGirl.build(:discipline_lesson_plan, lesson_plan: lesson_plan)

        expect(subject).to_not validate_presence_of(:classes)
      end
    end
  end
end
