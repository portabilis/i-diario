require 'rails_helper'

RSpec.describe AbsenceJustificationReportForm, type: :model do
  describe "validations" do
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:absence_date) }
    it { expect(subject).to validate_presence_of(:absence_date_end) }

    subject = AbsenceJustificationReportForm.new

    unity = FactoryGirl.create(
      :unity
    )

    exam_rule = FactoryGirl.create(
      :exam_rule
    )

    classroom = FactoryGirl.create(
      :classroom,
      exam_rule: exam_rule
    )

    classroom = FactoryGirl.create(
      :classroom,
      exam_rule: exam_rule
    )

    it "should validate if absence date end is lower than today" do
      subject.unity = unity
      subject.classroom_id = classroom.id
      subject.absence_date = Time.zone.today
      subject.absence_date_end = Time.zone.today + 1

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:absence_date_end]).to include("Deve ser menor ou igual a data de hoje")
    end

    it "should validate if absence date isn't greater than absence date end" do
      subject.unity = unity
      subject.classroom_id = classroom.id
      subject.absence_date = '26/06/2016'
      subject.absence_date_end = '25/04/2016'

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:absence_date]).to include("Data inicial não pode ser maior que a final")
    end
  end
end
