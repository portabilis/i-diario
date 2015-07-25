require 'rails_helper'

RSpec.describe SchoolCalendarStep, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }
  end

  describe "#to_s" do
    subject do
      school_calendar_step = school_calendar_steps(:school_calendar_step_a)
      school_calendar_step.start_at = '2015-01-01'
      school_calendar_step.end_at = '2015-03-01'
      school_calendar_step
    end

    it "returns localized start_at and end_at" do
      expect(subject.to_s).to eql('01/01/2015 a 01/03/2015')
    end
  end
end
