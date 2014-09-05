require 'spec_helper'

RSpec.describe ProfileUpdater, :type => :service do
  describe "with correct params" do

    let(:profile) { profiles(:admin) }

    let(:options) do
      {
        id: profile.id,
        permission: 'manage_users',
        value: false
      }
    end

    it 'updates a Profile' do
      updater = ProfileUpdater.new(options)
      old_permission = profile.manage_users

      updater.update

      expect(profile.reload.manage_users).to eq !old_permission
    end

    it 'set status' do
      updater = ProfileUpdater.new(options)
      old_permission = profile.manage_users

      updater.update

      expect(updater.status).to eq 200
    end
  end

  describe "without correct params" do

    let(:profile) { profiles(:admin) }

    let(:options) do
      {
        id: profile.id,
        permission: 'manage_users',
      }
    end

    it 'do not update the Profile' do
      updater = ProfileUpdater.new(options)
      old_permission = profile.manage_users

      updater.update

      expect(profile.reload.manage_users).to eq old_permission
    end

    it 'set status' do
      updater = ProfileUpdater.new(options)
      old_permission = profile.manage_users

      updater.update

      expect(updater.status).to eq 503
    end
  end
end
