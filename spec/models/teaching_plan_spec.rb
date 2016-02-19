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
    it { expect(subject).to validate_presence_of(:school_term_type) }

    context 'when school term type equals to yearly' do
      subject { build(:teaching_plan, school_term_type: SchoolTermTypes::YEARLY) }

      it { should_not validate_presence_of(:school_term) }
    end

    school_term_types = [SchoolTermTypes::BIMESTER, SchoolTermTypes::TRIMESTER, SchoolTermTypes::SEMESTER]
    school_term_types.each do |school_term|
      context "when school term type equals to #{school_term}" do
        subject { build(:teaching_plan, school_term_type: school_term) }

        it { should validate_presence_of(:school_term) }
      end
    end
  end
end
