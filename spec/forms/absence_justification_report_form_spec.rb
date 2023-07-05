require 'rails_helper'

RSpec.describe AbsenceJustificationReportForm, type: :model do
  describe "validations" do

    it { expect(subject).to validate_presence_of(:unity_id) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:absence_date) }
    it { expect(subject).to validate_presence_of(:absence_date_end) }

    it "should validate if absence date end is lower than today" do
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

      subject.unity_id = unity.id
      subject.classroom_id = classroom.id
      subject.absence_date = Time.zone.today
      subject.absence_date_end = Time.zone.today + 1

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:absence_date_end]).to include("deve ser menor ou igual a data de hoje")
    end

    it "should validate if absence date isn't greater than absence date end" do
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

      subject.unity_id = unity.id
      subject.classroom_id = classroom.id
      subject.absence_date = '04/05/2016'
      subject.absence_date_end = '03/05/2016'

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:absence_date]).to include("não pode ser maior que a Data final")
    end
  end
end
