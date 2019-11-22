require 'rails_helper'

RSpec.describe DisciplineTeachingPlan, type: :model do
  subject { build(:discipline_teaching_plan, :with_teacher_discipline_classroom) }

  describe 'associations' do
    it { expect(subject).to belong_to(:teaching_plan).dependent(:destroy) }
    it { expect(subject).to belong_to(:discipline) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:teaching_plan) }
    it { expect(subject).to validate_presence_of(:discipline) }

    it 'should validate uniqueness of discipline teaching plan' do
      another_discipline_teaching_plan = create(:discipline_teaching_plan, :with_teacher_discipline_classroom)

      teaching_plan = create(
        :teaching_plan,
        year: another_discipline_teaching_plan.teaching_plan.year,
        unity: another_discipline_teaching_plan.teaching_plan.unity,
        grade: another_discipline_teaching_plan.teaching_plan.grade,
        school_term: another_discipline_teaching_plan.teaching_plan.school_term,
        teacher: another_discipline_teaching_plan.teaching_plan.teacher
      )
      subject = build(
        :discipline_teaching_plan,
        teaching_plan: teaching_plan,
        discipline: another_discipline_teaching_plan.discipline
      )

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:base]).to include('Já existe um plano de ensino para o período informado')
    end
  end
end
