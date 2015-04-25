# encoding: utf-8
require 'rails_helper'

RSpec.describe SchoolCalendar, :type => :model do
  describe "associations" do
    it { should have_many :steps }
  end

  describe "validations" do
    it { should validate_presence_of :year }
    it { should validate_presence_of :number_of_classes }

    it "validates at least one assigned step" do
      subject.steps = []

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:steps]).to include
        "É necessário adicionar pelo menos uma etapa"
    end
  end

  describe "#school_day?" do
    school_calendar = SchoolCalendar.new(year: 2020, number_of_classes: 5)
    school_calendar.steps.build(start_at: '2020-02-15', end_at: '2020-05-01')
    school_calendar.save!
    school_calendar.events.create(event_date: '2020-04-25', description: 'Dia extra letivo', event_type: EventTypes::EXTRA_SCHOOL)

    context "when the date is school day with a holiday event" do
      it "should return false" do
        date = '2020-04-21'.to_date
        expect(school_calendar.school_day? date).to eq(false)
      end
    end

    context "when the date is a weekend day" do
      it "should return false" do
        date = '2020-05-03'.to_date
        expect(school_calendar.school_day? date).to eq(false)
      end
    end

    context "when the date is a weekend day with extra school event" do
      it "should return true" do
        date = '2020-04-25'.to_date
        expect(school_calendar.school_day? date).to eq(true)
      end
    end

    context "when the date is school day without a holiday event" do
      it "should return true" do
        date = '2020-04-20'.to_date
        expect(school_calendar.school_day? date).to eq(true)
      end
    end
  end
end
