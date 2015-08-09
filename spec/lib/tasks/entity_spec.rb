require 'spec_helper'
require 'rake'

describe 'entity' do
  describe 'entity:setup' do
    before do
      load File.expand_path("../../../../lib/tasks/entity.rake", __FILE__)
      Rake::Task.define_task(:environment)

      ENV["NAME"] = "Entidade X"
      ENV["DOMAIN"] = "domain.x"
      ENV["DATABASE"] = "database_x"
    end

    it "should call EntityCreator with the options" do
      creator = double("creator", status: 'success')

      expect(EntityCreator).to receive(:new).with(ENV).and_return(creator)
      expect(creator).to receive(:setup)

      Rake::Task["entity:setup"].invoke
    end
  end
end
