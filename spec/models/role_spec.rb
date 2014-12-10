require 'rails_helper'

RSpec.describe Role, :type => :model do
  context "Associations" do
    it { should belong_to :author }
    it { should have_many :permissions }
  end

  context "Validations" do
    it { should validate_presence_of :author }
    it { should validate_presence_of :name }
  end

  describe "#to_s" do
    it "returns name" do
      subject.name = "administrador"
      expect(subject.to_s).to eq "administrador"
    end
  end
end
