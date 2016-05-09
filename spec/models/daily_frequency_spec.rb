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
    it { expect(subject).to validate_school_calendar_day_of(:frequency_date) }
    it { should validate_presence_of :school_calendar }
  end
end
