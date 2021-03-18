require 'rails_helper'

RSpec.describe TeachingPlan, type: :model do
  subject { build(:teaching_plan) }

  describe 'associations' do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:grade) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:year) }
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:grade) }

    context 'when school term type is yearly' do
      subject { build(:teaching_plan, school_term_type: nil) }

      it { should_not validate_presence_of(:school_term_type) }
      it { should_not validate_presence_of(:school_term_type_step) }
    end

    context 'when contents has no records assigneds' do
      it 'should validate if at leat one record is assigned' do
        subject = build(:teaching_plan, :without_contents)

        expect(subject).to_not be_valid
        expect(subject.errors.messages[:contents]).to include('Deve possuir pelo menos um conteúdo')
      end
    end
  end
end
