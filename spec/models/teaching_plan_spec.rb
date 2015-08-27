require 'rails_helper'

RSpec.describe TeachingPlan, type: :model do
  subject { FactoryGirl.build(:teaching_plan) }

  describe 'attributes' do
    it { expect(subject).to respond_to(:year) }
    it { expect(subject).to respond_to(:unity_id) }
    it { expect(subject).to respond_to(:classroom) }
    it { expect(subject).to respond_to(:discipline) }
    it { expect(subject).to respond_to(:school_term_type) }
    it { expect(subject).to respond_to(:school_term) }
    it { expect(subject).to respond_to(:objectives) }
    it { expect(subject).to respond_to(:content) }
    it { expect(subject).to respond_to(:methodology) }
    it { expect(subject).to respond_to(:evaluation) }
    it { expect(subject).to respond_to(:references) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:year) }
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:discipline) }
    it { expect(subject).to validate_presence_of(:school_term_type) }

    it 'should validate uniqueness of teaching plan in year/unity/classroom/discipline/school_term' do
      another_teaching_plan = FactoryGirl.create(:teaching_plan, year: subject.year,
                                                                 classroom: subject.classroom,
                                                                 discipline: subject.discipline,
                                                                 school_term_type: subject.school_term_type,
                                                                 school_term: subject.school_term)

      expect(subject).to_not be_valid
      expect(subject.errors[:school_term_type]).to include('já existe um plano de ensino para a turma e disciplina informadas neste período')
    end

    context 'when school term type equals to yearly' do
      it 'should not validate presence of school term' do
        subject.school_term_type = SchoolTermTypes::YEARLY
        subject.school_term      = nil

        expect(subject.valid?).to be(true)
        expect(subject.errors[:school_term]).to be_empty
      end
    end

    school_term_types = [SchoolTermTypes::BIMESTER, SchoolTermTypes::TRIMESTER, SchoolTermTypes::SEMESTER]
    school_term_types.each do |school_term|
      context "when school term type equals to #{school_term}" do
        it 'should validate presence of school term' do
          subject.school_term_type = school_term
          subject.school_term      = nil

          expect(subject.valid?).to be(false)
          expect(subject.errors[:school_term]).to include('não pode ficar em branco')
        end
      end
    end
  end
end
