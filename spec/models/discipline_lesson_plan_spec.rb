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

    it 'should validate uniqueness of discipline lesson plan' do
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

      expect(subject).to_not be_valid
      expect(subject.lesson_plan.errors.messages[:base]).to include('Já existe um plano de aula para o período informado')
    end
  end
end
