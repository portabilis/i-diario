require 'rails_helper'

RSpec.describe IndividualizedEducationalPlanPolicy do
  let(:record) { build(:individualized_educational_plan) }
  let(:user) { instance_double(User) }

  subject { described_class.new(user, record) }

  describe 'feature permissions' do
    it 'allows index/show when the user can view the feature' do
      allow(user).to receive(:can_show?).with('individualized_educational_plans').and_return(true)

      expect(subject.index?).to eq(true)
      expect(subject.show?).to eq(true)
    end

    it 'denies index/show when the user cannot view the feature' do
      allow(user).to receive(:can_show?).with('individualized_educational_plans').and_return(false)

      expect(subject.index?).to eq(false)
    end

    it 'allows create/update when the user can change the feature' do
      allow(user).to receive(:can_change?).with('individualized_educational_plans').and_return(true)

      expect(subject.create?).to eq(true)
      expect(subject.update?).to eq(true)
    end
  end

  describe '#finalize?' do
    it 'delegates to update? — allowed when the user can change the feature' do
      allow(user).to receive(:can_change?).with('individualized_educational_plans').and_return(true)

      expect(subject.finalize?).to eq(true)
    end

    it 'denies when the user cannot change the feature' do
      allow(user).to receive(:can_change?).with('individualized_educational_plans').and_return(false)

      expect(subject.finalize?).to eq(false)
    end
  end
end
