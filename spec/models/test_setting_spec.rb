# encoding: utf-8
require 'rails_helper'

RSpec.describe TestSetting, :type => :model do
  describe "associations" do
    it { should have_many :tests }
  end

  describe "validations" do
    it { should validate_presence_of :year }

    it "validates at least one assigned test" do
      subject.tests = []
      subject.fix_tests = true

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:tests]).to include
        "É necessário pelo menos uma avaliação"
    end
  end
end
