# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyFrequency, :type => :model do
  describe "associations" do
    it { should belong_to :unity }
    it { should belong_to :classroom }
    it { should belong_to :discipline }
    it { should belong_to :school_calendar }
    it { should have_many :students }
  end

  describe "validations" do
    it { should validate_presence_of :unity }
    it { should validate_presence_of :classroom }
    it { should validate_presence_of :frequency_date }
    it { should validate_presence_of :school_calendar }

    context "it is global absence" do
      before { subject.global_absence = true }

      it { should_not validate_presence_of :discipline }
    end

    context "it is not global absence" do
      before { subject.global_absence = false }

      it { should validate_presence_of :discipline }
    end
  end
end
