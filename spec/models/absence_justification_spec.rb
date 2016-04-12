require 'rails_helper'

RSpec.describe AbsenceJustification, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:author) }
    it { expect(subject).to belong_to(:student) }
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:author) }
    it { expect(subject).to validate_presence_of(:student_id) }
    it { expect(subject).to validate_presence_of(:absence_date) }
    it { expect(subject).to validate_presence_of(:absence_date_end) }
    it { expect(subject).to validate_presence_of(:justification) }
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:school_calendar)}

    context "given that I have a record persisted" do
      fixtures :students, :absence_justifications

      it { expect(subject).to validate_uniqueness_of(:absence_date).scoped_to(:student_id) }
      it { expect(subject).to validate_uniqueness_of(:absence_date_end).scoped_to(:student_id) }
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
          unity: unity
        )

        absence_justification = FactoryGirl.create(
          :absence_justification,
          unity: unity,
          school_calendar: school_calendar,
          classroom: classroom,
          discipline: discipline,
          student: student,
          absence_date: '07/04/2016',
          absence_date_end: '09/04/2016'
        )

        subject = FactoryGirl.build(
          :absence_justification,
          unity: unity,
          school_calendar: school_calendar,
          classroom: classroom,
          student: student,
          discipline: discipline,
          absence_date: '08/04/2016',
          absence_date_end: '08/04/2016'
        )

        expect(subject).to_not be_valid
        expect(subject.errors.messages[:base]).to include('Já existe uma justificativa para a disciplina e período informados')
      end
    end
  end
end
