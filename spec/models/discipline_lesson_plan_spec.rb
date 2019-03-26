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

    it 'should allow more than one discipline lesson plan in the same date' do
      another_lesson_plan = FactoryGirl.create(
        :lesson_plan,
        start_at: '30/06/2020',
        end_at: '30/06/2020'
      )
      another_discipline_lesson_plan = FactoryGirl.create(
        :discipline_lesson_plan,
        lesson_plan: another_lesson_plan
      )

      lesson_plan = FactoryGirl.create(
        :lesson_plan,
        school_calendar: another_lesson_plan.school_calendar,
        classroom: another_lesson_plan.classroom,
        start_at: '01/06/2020',
        end_at: '01/07/2020'
      )
      subject = FactoryGirl.build(
        :discipline_lesson_plan,
        lesson_plan: lesson_plan,
        discipline: another_discipline_lesson_plan.discipline
      )

      expect(subject).to be_valid
      expect(subject.errors[:lesson_plan].any?).to be(false)
    end
  end
end
