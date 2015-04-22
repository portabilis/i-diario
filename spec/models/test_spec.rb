require 'rails_helper'

RSpec.describe Test, :type => :model do
  describe "associations" do
    it { should belong_to :unity }
    it { should belong_to :classroom }
    it { should belong_to :discipline }
    it { should belong_to :school_calendar }
    it { should belong_to :test_setting }
    it { should belong_to :test_setting_test }
  end

  describe "validations" do
    it { should validate_presence_of :unity }
    it { should validate_presence_of :classroom }
    it { should validate_presence_of :discipline }
    it { should validate_presence_of :school_calendar }
    it { should validate_presence_of :test_setting }
    it { should validate_presence_of :test_date }
    it { should validate_presence_of :class_number }

    context "when configuration fix tests" do
      before { subject.test_setting = TestSetting.new(fix_tests: true) }

      it { should validate_presence_of :test_setting_test }
    end

    context "when configuration not fix tests" do
      before { subject.test_setting = TestSetting.new(fix_tests: false) }

      it { should validate_presence_of :description }
    end
  end
end
