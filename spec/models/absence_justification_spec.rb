require 'rails_helper'

RSpec.describe AbsenceJustification, type: :model do
  subject(:absence_justification) { build(:absence_justification) }
  let(:frequency_type_definer) { FrequencyTypeDefiner.new(subject.classroom, subject.teacher) }

  describe 'associations' do
    it { expect(subject).to belong_to(:teacher) }
    it { expect(subject).to belong_to(:user) }
    it { expect(subject).to have_many(:students) }
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to have_many(:absence_justifications_students) }
    it { expect(subject).to have_many(:students).through(:absence_justifications_students) }
    it { expect(subject).to have_many(:absence_justifications_disciplines) }
    it { expect(subject).to have_many(:disciplines).through(:absence_justifications_disciplines) }
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:teacher) }
    it { expect(subject).to validate_presence_of(:absence_date) }
    it { expect(subject).to validate_school_calendar_day_of(:absence_date) }
    it { expect(subject).to validate_presence_of(:absence_date_end) }
    it { expect(subject).to validate_school_calendar_day_of(:absence_date_end) }
    it { expect(subject).to validate_presence_of(:unity) }
    it do
      allow(FrequencyTypeDefiner).to receive(:new).and_return(frequency_type_definer)

      expect(subject).to validate_presence_of(:classroom_id)
    end
    it { expect(subject).to validate_presence_of(:school_calendar) }

    context 'given that I have a record persisted' do
      it 'should validate if is a valid date on a absence with frequence type by discipline' do
        skip 'disciplines will not be able in future'

        classroom = create(
          :classroom,
          :with_classroom_semester_steps,
          :by_discipline
        )

        teacher_discipline_classroom = create(
          :teacher_discipline_classroom,
          classroom: classroom,
          grade: classroom.classrooms_grades.first.grade
        )

        school_calendar = classroom.calendar.school_calendar
        teacher = teacher_discipline_classroom.teacher
        user = create(:user, assumed_teacher_id: teacher.id)
        first_school_calendar_date = Date.current
        absence = create(
          :absence_justification,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          absence_date: first_school_calendar_date,
          absence_date_end: first_school_calendar_date + 2,
          teacher: teacher,
          user: user
        )

        subject = build(
          :absence_justification,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          absence_date: first_school_calendar_date + 1,
          absence_date_end: first_school_calendar_date + 1,
          teacher: teacher,
          user: user
        )
        subject.students << absence.students.first
        subject.disciplines << absence.disciplines.first

        expect(subject).to_not be_valid

        expect(subject.errors.messages[:base]).to(
          include('Já existe uma justificativa para a disciplina e período informados')
        )
      end
    end
  end
end
