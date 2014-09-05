require 'spec_helper'
require 'rake'

describe 'profiles' do
  describe 'profiles:setup' do
    before do
      load File.expand_path("../../../../lib/tasks/profiles_setup.rake", __FILE__)
      Rake::Task.define_task(:environment)
    end

    it "should call ProfilesCreator" do
      creator = double("creator", status: 'success')

      ProfilesCreator.should_receive(:new).and_return(creator)
      creator.should_receive(:setup)

      Rake::Task["profiles:setup"].invoke
    end
  end
end
