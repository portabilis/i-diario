# encoding: utf-8
require 'rails_helper'

RSpec.describe SchoolCalendarEvent, :type => :model do
  describe "associations" do
    it { should belong_to :school_calendar }
  end

  describe "validations" do
    it { should validate_presence_of :event_date }
    it { should validate_presence_of :description }
    it { should validate_presence_of :event_type }
  end
end
