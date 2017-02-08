require 'rails_helper'

RSpec.describe Deficiency, :type => :model do
  context "Validations" do
    it { should validate_presence_of :name }
  end

  describe "#to_s" do
    it "returns the name" do
      subject.name = "Cegueira"

      expect(subject.to_s).to eq "Cegueira"
    end
  end
end
