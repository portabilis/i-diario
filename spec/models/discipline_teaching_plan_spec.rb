require 'rails_helper'

RSpec.describe DisciplineTeachingPlan, type: :model do
  subject { build(:discipline_teaching_plan, :with_teacher_discipline_classroom) }

  before do
    allow_any_instance_of(TeachingPlan).to receive(:yearly?).and_return(true)
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:teaching_plan).dependent(:destroy) }
    it { expect(subject).to belong_to(:discipline) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:teaching_plan) }
    it { expect(subject).to validate_presence_of(:discipline) }

    it 'should validate uniqueness of discipline teaching plan' do
      other_teaching_plan = create(:discipline_teaching_plan, :with_teacher_discipline_classroom)

      subject = build(
        :discipline_teaching_plan,
        teaching_plan: other_teaching_plan.teaching_plan,
        discipline: other_teaching_plan.discipline
      )

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:base]).to include('Já existe um plano de ensino para o período informado')
    end
  end
end
