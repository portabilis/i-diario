require 'rails_helper'

RSpec.describe AbsenceJustification, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:teacher) }
    it { expect(subject).to belong_to(:student) }
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:teacher) }
    it { expect(subject).to validate_presence_of(:student_id) }
    it { expect(subject).to validate_presence_of(:absence_date) }
    it { expect(subject).to validate_school_calendar_day_of(:absence_date) }
    it { expect(subject).to validate_presence_of(:absence_date_end) }
    it { expect(subject).to validate_school_calendar_day_of(:absence_date_end) }
    it { expect(subject).to validate_presence_of(:justification) }
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:school_calendar)}

    context "given that I have a record persisted" do
      fixtures :students, :absence_justifications

      it "should validate if is a valid date on a absence with frequence type by discipline" do
        exam_rule = FactoryGirl.create(
          :exam_rule_by_discipline
        )

        classroom = FactoryGirl.create(
          :classroom,
          exam_rule: exam_rule
        )

        student = FactoryGirl.create(
          :student
        )

        unity = FactoryGirl.create(
          :unity
        )

        discipline = FactoryGirl.create(
          :discipline
        )

        school_calendar = FactoryGirl.create(
          :school_calendar_with_one_step,
          year: 2016,
          unity: unity
        )

        absence_justification = FactoryGirl.create(
          :absence_justification,
          unity: unity,
          school_calendar: school_calendar,
          classroom: classroom,
          discipline: discipline,
          student: student,
          absence_date: '12/04/2016',
          absence_date_end: '14/04/2016'
        )

        subject = FactoryGirl.build(
          :absence_justification,
          unity: unity,
          school_calendar: school_calendar,
          classroom: classroom,
          student: student,
          discipline: discipline,
          absence_date: '13/04/2016',
          absence_date_end: '13/04/2016'
        )

        expect(subject).to_not be_valid
        expect(subject.errors.messages[:base]).to include('Já existe uma justificativa para a disciplina e período informados')
      end
    end
  end
end
