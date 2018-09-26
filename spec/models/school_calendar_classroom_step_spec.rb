require 'rails_helper'

RSpec.describe SchoolCalendarClassroomStep, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:school_calendar_classroom) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }
    it { expect(subject).to validate_presence_of(:start_date_for_posting) }
    it { expect(subject).to validate_presence_of(:end_date_for_posting) }

    it "validates that start_at is in school_calendar year" do
      school_calendar = build(:school_calendar, year: 2020)
      classroom = build(:classroom)
      school_calendar_classroom = build(:school_calendar_classroom, school_calendar: school_calendar, classroom: classroom)
      subject.school_calendar_classroom = school_calendar_classroom
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

    it "validates that start_at is less than start_date_for_posting" do
      subject.start_at = "02/01/2020"
      subject.start_date_for_posting = "01/01/2020"

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:start_date_for_posting]).to include("não pode ser menor que a data inicial")
    end

    it "validates that start_at is less than end_date_for_posting " do
      subject.start_at = "02/01/2020"
      subject.end_date_for_posting = "01/01/2020"

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:end_date_for_posting]).to include("não pode ser menor que a data inicial")
    end

    it "validates that start_date_for_posting is less than end_date_for_posting" do
      subject.start_date_for_posting = "02/01/2020"
      subject.end_date_for_posting = "01/01/2020"

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:end_date_for_posting]).to include("não pode ser menor que a data inicial para lançamentos")
    end
  end
end
