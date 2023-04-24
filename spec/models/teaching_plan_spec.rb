require 'rails_helper'

RSpec.describe TeachingPlan, type: :model do
  let!(:school_term_type) { create(:school_term_type) }

  let!(:school_term_type_step) { create(:school_term_type_step, school_term_type: school_term_type) }
  subject { build(
    :teaching_plan,
    school_term_type: school_term_type,
    school_term_type_step: school_term_type_step)
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:grade) }
  end

  describe 'validations' do
    it {
      TeachingPlan.any_instance.stub(:yearly?).and_return(true)
      expect(subject).to validate_presence_of(:year)
    }
    it {
      TeachingPlan.any_instance.stub(:yearly?).and_return(true)
      expect(subject).to validate_presence_of(:unity)
    }
    it {
      TeachingPlan.any_instance.stub(:yearly?).and_return(true)
      expect(subject).to validate_presence_of(:grade)
    }

    context 'when school term type is yearly' do
      subject { build(:teaching_plan, school_term_type: nil, school_term_type_step: nil) }

      it { expect(subject.school_term_type).to_not be_present  }
      it { expect(subject.school_term_type_step).to_not be_present  }
    end

    context 'when contents has no records assigneds' do
      it 'should validate if at leat one record is assigned' do
        TeachingPlan.any_instance.stub(:yearly?).and_return(true)

        subject = build(
          :teaching_plan,
          :without_contents,
          school_term_type: school_term_type,
          school_term_type_step: school_term_type_step
        )

        expect(subject).to_not be_valid
        expect(subject.errors.messages[:contents]).to include('Deve possuir pelo menos um conteúdo')
      end
    end
  end
end
