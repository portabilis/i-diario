require 'rails_helper'

RSpec.describe Avaliation, :type => :model do
#  fixtures :school_calendars, :school_calendar_steps

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
      before { subject.test_setting = TestSetting.new(fix_tests: true); subject.school_calendar = SchoolCalendar.first }

      it { should validate_presence_of :test_setting_test }
    end

    context "when configuration not fix tests" do
      before { subject.test_setting = TestSetting.new(fix_tests: false); subject.school_calendar = SchoolCalendar.first }

      it { should validate_presence_of :description }
    end
  end
end
