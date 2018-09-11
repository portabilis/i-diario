require 'rails_helper'

RSpec.describe UserRole, :type => :model do
  let(:role) { create(:role) }

  describe '#can_change_school_year?' do
    before { subject.role = role }

    context 'role hasnt permissions' do
      before { subject.role.permissions.delete }

      it { expect(subject.can_change_school_year?).to eql(false) }
    end

    context 'role permission exists' do
      context 'permission is denied ' do
        before { subject.role.permissions.create!(feature: Features::CHANGE_SCHOOL_YEAR , permission: Permissions::DENIED) }

        it { expect(subject.can_change_school_year?).to eql(false) }
      end

      context 'permission is change' do
        before { subject.role.permissions.create!(feature: Features::CHANGE_SCHOOL_YEAR , permission: Permissions::CHANGE) }

        it { expect(subject.can_change_school_year?).to eql(true) }
      end
    end
  end
end
