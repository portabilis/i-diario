require 'spec_helper'

RSpec.describe Profile, :type => :model do
  context 'validations' do
    it { should validate_presence_of :role }
    it { should validate_uniqueness_of :role }
  end

  context 'permissions defaults' do
    it 'should use false as default for manage_profiles' do
      expect(subject.manage_profiles).to eq false
    end

    it 'should use false as default for manage_users' do
      expect(subject.manage_users).to eq false
    end
  end

  context '#permissions_list' do
    it 'returns the permissions list' do
      expect(subject.class.permissions_list).to eq ['manage_profiles', 'manage_users']
    end
  end
end
