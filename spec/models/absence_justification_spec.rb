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

  describe '#period_absence validation' do
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom, classroom: classroom)
    end
    let(:school_calendar) { classroom.calendar.school_calendar }
    let(:teacher) { teacher_discipline_classroom.teacher }
    let(:user) { create(:user, assumed_teacher_id: teacher.id) }
    let(:student) { create(:student) }
    let(:discipline) { create(:discipline) }
    let(:absence_date) { Date.current }
    let(:absence_date_end) { Date.current + 1 }

    before do
      allow_any_instance_of(AbsenceJustification).to receive(:current_user).and_return(user)
    end

    context 'legacy justifications (until 2023) - only validation of existing records.' do
      # IMPORTANTE: Registros legacy não serão mais criados (apenas existem no histórico até 2023)

      before do
        allow_any_instance_of(AbsenceJustification).to receive(:frequence_type_by_discipline?).and_return(true)
      end

      it 'validates by disciplines when legacy=true AND frequence_type_by_discipline=true AND discipline_ids.present=true' do

        legacy_with_disciplines = build(:absence_justification,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          teacher: teacher,
          user: user,
          legacy: true
        )
        legacy_with_disciplines.students << student
        legacy_with_disciplines.disciplines << discipline
        legacy_with_disciplines.current_user = user

        expect(legacy_with_disciplines.valid?).to be true
      end
    end

    context 'non-legacy justifications (2023+) - validation by period and class_number' do
      # IMPORTANTE: A partir de 2023, justificativas NÃO têm mais vínculo com disciplinas

      before do
        allow_any_instance_of(AbsenceJustification).to receive(:frequence_type_by_discipline?).and_return(false)
      end

      it 'when record is not legacy' do
        new_absence = build(:absence_justification,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          teacher: teacher,
          user: user,
          legacy: false,
          period: Periods::MATUTINAL,
          class_number: 1
        )
        new_absence.current_user = user

        expect(new_absence.valid?).to be true
      end

      it 'validates by period when present' do
        absence_with_period = build(:absence_justification,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          teacher: teacher,
          user: user,
          legacy: false,
          period: Periods::MATUTINAL
        )
        absence_with_period.current_user = user

        expect(absence_with_period.valid?).to be true
      end

      it 'validates by class_number correctly including nil values' do
        # Teste com class_number preenchido
        with_class_number = build(:absence_justification,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          teacher: teacher,
          user: user,
          legacy: false,
          period: Periods::MATUTINAL,
          class_number: 1
        )
        with_class_number.current_user = user
        expect(with_class_number.valid?).to be true

        # Teste com class_number nil
        without_class_number = build(:absence_justification,
          unity: classroom.unity,
          school_calendar: school_calendar,
          classroom: classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          teacher: teacher,
          user: user,
          legacy: false,
          period: Periods::MATUTINAL,
          class_number: nil
        )
        without_class_number.current_user = user
        expect(without_class_number.valid?).to be true
      end

      it 'when it identifies duplicate records of justified absences with class_number = nil' do
        # Cria primeira justificativa com class_number nil
        first_absence = create(
          :absence_justification,
          teacher_discipline_classroom: teacher_discipline_classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          user: user,
          legacy: false,
          period: Periods::MATUTINAL,
          class_number: nil
        )

        # Tenta criar segunda justificativa com os MESMOS teacher, classroom, dates, period, class_number
        duplicate_absence = build(
          :absence_justification,
          teacher_discipline_classroom: teacher_discipline_classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          user: user,
          legacy: false,
          period: Periods::MATUTINAL,
          class_number: nil
        )

        # Adiciona o MESMO student do first_absence
        duplicate_absence.students = [first_absence.students.first]
        duplicate_absence.current_user = user

        # Tenta salvar - deve falhar na validação
        result = duplicate_absence.save

        expect(result).to be false
        expect(duplicate_absence).to_not be_valid
        expect(duplicate_absence.errors[:base]).to include(
          "Já existe uma justificativa de falta no período informado para o(a) professor(a) #{first_absence.teacher.name}"
        )
      end

      it 'when identifying duplicate records of justified absences with class number = 1' do
        # Cria primeira justificativa com class_number 1
        first_absence = create(
          :absence_justification,
          teacher_discipline_classroom: teacher_discipline_classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          user: user,
          legacy: false,
          period: Periods::MATUTINAL,
          class_number: 1
        )

        # Tenta criar segunda justificativa com os MESMOS teacher, classroom, dates, period, class_number
        duplicate_absence = build(
          :absence_justification,
          teacher_discipline_classroom: teacher_discipline_classroom,
          absence_date: absence_date,
          absence_date_end: absence_date_end,
          user: user,
          legacy: false,
          period: Periods::MATUTINAL,
          class_number: 1
        )

        # Adiciona o MESMO student do first_absence
        duplicate_absence.students = [first_absence.students.first]
        duplicate_absence.current_user = user

        # Tenta salvar - deve falhar na validação
        result = duplicate_absence.save

        expect(result).to be false
        expect(duplicate_absence).to_not be_valid
        expect(duplicate_absence.errors[:base]).to include(
          "Já existe uma justificativa de falta no período informado para o(a) professor(a) #{first_absence.teacher.name}"
        )
      end
    end
  end
end
