require 'rails_helper'

RSpec.describe SchoolCalendarStep, :type => :model do
  describe "associations" do
    it { should belong_to :school_calendar }
  end

  describe "validations" do
    it { should validate_presence_of :start_at }
    it { should validate_presence_of :end_at }
  end
end
