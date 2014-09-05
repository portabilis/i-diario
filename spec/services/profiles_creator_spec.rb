# encoding: utf-8
require 'spec_helper'

RSpec.describe ProfilesCreator, :type => :service do
  describe "with correct params" do
    before do
      Profile.destroy_all
    end

    it 'creates the Profiles' do
      creator = ProfilesCreator.new

      expect{ creator.setup }.to change{ Profile.count }.by(4)

      profiles = Profile.all

      expect(profiles[0].role).to eq 'admin'
      expect(profiles[1].role).to eq 'parent'
      expect(profiles[2].role).to eq 'servant'
      expect(profiles[3].role).to eq 'student'
    end

    it 'set success message' do
      creator = ProfilesCreator.new

      creator.setup

      expect(creator.status).to eq "\nPerfis de usuário criados com sucesso."
    end
  end
end
