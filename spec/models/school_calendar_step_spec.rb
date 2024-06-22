# encoding: utf-8

require 'rails_helper'

RSpec.describe SchoolCalendarStep, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }
    it { expect(subject).to validate_presence_of(:start_date_for_posting) }
    it { expect(subject).to validate_presence_of(:end_date_for_posting) }

    it "validates that start_at is less than end_at" do
      subject.start_at = "01/01/2020"
      subject.end_at = "01/01/2020"

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:start_at]).to include('não pode ser maior ou igual a data final')
    end

    it "validates that start_date_for_posting is less than end_date_for_posting" do
      subject.start_date_for_posting = "02/01/2020"
      subject.end_date_for_posting = "01/01/2020"

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:end_date_for_posting]).to include("não pode ser menor que a data inicial para lançamentos")
    end

    it 'start_at date should not have conflicting school terms with other school calendars from the same unity' do
      existing_school_calendar = build(:school_calendar, year: 2020)
      existing_school_calendar.steps.build(
        start_at: '2020-02-15',
        end_at: '2021-01-30',
        start_date_for_posting: '2020-02-15',
        end_date_for_posting: '2021-01-30'
      )
      existing_school_calendar.save!

      school_calendar = build(:school_calendar, year: 2021, unity: existing_school_calendar.unity)
      subject.school_calendar = school_calendar
      subject.start_at = '2021-01-20'
      subject.end_at = '2021-10-10'
      subject.start_date_for_posting = '2021-01-20'
      subject.end_date_for_posting = '2021-10-10'

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:start_at]).to include('A data informada não pode ser um dia letivo em outro calendário escolar')
    end

    it 'end_at date should not have conflicting school terms with other school calendars from the same unity' do
      existing_school_calendar = build(:school_calendar, year: 2021)
      existing_school_calendar.steps.build(
        start_at: '2021-01-15',
        end_at: '2021-07-19',
        start_date_for_posting: '2021-01-15',
        end_date_for_posting: '2021-07-19'
      )
      existing_school_calendar.save!

      school_calendar = build(:school_calendar, year: 2020, unity: existing_school_calendar.unity)
      subject.school_calendar = school_calendar
      subject.start_at = '2020-07-20'
      subject.end_at = '2021-01-20'
      subject.start_date_for_posting = '2020-07-20'
      subject.end_date_for_posting = '2021-01-20'

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:end_at]).to include('A data informada não pode ser um dia letivo em outro calendário escolar')
    end
  end

  describe "#to_s" do
    subject do
      school_calendar_step = build(:school_calendar_step)
      school_calendar_step.school_calendar.steps << school_calendar_step
      school_calendar_step.start_at = '2015-01-01'
      school_calendar_step.end_at = '2015-03-01'
      school_calendar_step
    end

    it "returns localized start_at and end_at" do
      expect(subject.to_s).to include('01/01/2015 a 01/03/2015')
    end
  end

  describe "#to_number" do
    subject do
      school_calendar_step = build(:school_calendar_step)
      school_calendar_step
    end

    it "returns step number" do
      expect(subject.to_number).to eql(1)
    end
  end
end
