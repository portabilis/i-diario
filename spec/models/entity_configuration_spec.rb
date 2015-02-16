require 'rails_helper'

RSpec.describe EntityConfiguration, :type => :model do
  describe ".current" do
    context "when it doesn't have a existent configuration" do
      it "returns a new configuration" do
        expect(EntityConfiguration.current).to be_new_record
      end
    end

    context "when it has a persited configuration" do
      it "return the first persited configuration" do
        entity_configuration = EntityConfiguration.create
        expect(EntityConfiguration.current).to eq entity_configuration
      end
    end
  end
end
