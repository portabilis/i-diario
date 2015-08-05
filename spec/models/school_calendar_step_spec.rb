# encoding: utf-8

require 'rails_helper'

RSpec.describe SchoolCalendarStep, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }

    it "validates that start_at is in school_calendar year" do
      school_calendar = build(:school_calendar, year: 2020)
      subject.school_calendar = school_calendar
      subject.start_at = "01/01/2022"

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:start_at]).to include('não pode ter o ano diferente do calendário escolar')
    end

    it "validates that start_at is less than end_at" do
      subject.start_at = "01/01/2020"
      subject.end_at = "01/01/2020"

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:start_at]).to include('não pode ser maior ou igual a data final')
    end

    it "validates that end_at is in school_calendar year" do
      school_calendar = build(:school_calendar, year: 2020)
      subject.school_calendar = school_calendar
      subject.end_at = "01/01/2022"

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:end_at]).to include('não pode ter o ano diferente do calendário escolar')
    end
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
