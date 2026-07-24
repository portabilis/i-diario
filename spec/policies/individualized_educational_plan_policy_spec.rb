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

    it 'allows update when the user can change the feature' do
      allow(user).to receive(:can_change?).with('individualized_educational_plans').and_return(true)

      expect(subject.update?).to eq(true)
      expect(subject.edit?).to eq(true)
    end
  end

  # 7876: criação e exclusão são de gestão (admin/servidor). O professor edita as seções 4/5
  # do próprio componente e pode finalizar, mas não cria nem exclui.
  describe 'create/new/destroy by role' do
    before { allow(user).to receive(:can_change?).with('individualized_educational_plans').and_return(true) }

    context 'as an admin or employee' do
      before { allow(user).to receive(:current_role_is_admin_or_employee?).and_return(true) }

      it 'allows create, new and destroy' do
        expect(subject.create?).to eq(true)
        expect(subject.new?).to eq(true)
        expect(subject.destroy?).to eq(true)
      end
    end

    context 'as a teacher' do
      before { allow(user).to receive(:current_role_is_admin_or_employee?).and_return(false) }

      it 'denies create, new and destroy' do
        expect(subject.create?).to eq(false)
        expect(subject.new?).to eq(false)
        expect(subject.destroy?).to eq(false)
      end

      it 'still allows update and finalize' do
        expect(subject.update?).to eq(true)
        expect(subject.finalize?).to eq(true)
      end
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
