require 'rails_helper'

RSpec.describe Api::EnrollmentDailyFrequencyStatusesService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  before(:all) { travel_to Time.zone.local(2026, 6, 30, 12, 0, 0) }
  after(:all) { travel_back }

  let(:year) { 2026 }
  let(:start_at) { Date.new(year, 3, 1) }
  let(:end_at) { Date.new(year, 3, 31) }
  let(:classroom) { create(:classroom, year: year, api_code: '001') }
  let!(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
  let!(:school_calendar) { create(:school_calendar, year: year, unity: classroom.unity) }
  let!(:school_calendar_step) do
    create(
      :school_calendar_step,
      school_calendar: school_calendar,
      step_number: 1,
      start_at: Date.new(year, 1, 1),
      end_at: Date.new(year, 12, 31),
      start_date_for_posting: Date.new(year, 1, 1),
      end_date_for_posting: Date.new(year, 12, 31)
    )
  end
  let(:student_enrollment_classroom) do
    create(:student_enrollment_classroom, classrooms_grade: classrooms_grade, joined_at: '2026-02-01')
  end
  let(:student_enrollment) { student_enrollment_classroom.student_enrollment }
  let(:student) { student_enrollment.student }
  let(:discipline) { create(:discipline) }

  # Dias úteis de março/2026 sem feriado nacional
  let(:monday) { Date.new(year, 3, 2) }
  let(:tuesday) { Date.new(year, 3, 3) }
  let(:wednesday) { Date.new(year, 3, 4) }

  before do
    student_enrollment.update!(api_code: 'EN001') if student_enrollment.api_code.blank?
  end

  def call_service(api_code: student_enrollment.api_code, from: start_at, to: end_at)
    described_class.call(student_enrollment_api_code: api_code, start_at: from, end_at: to)
  end

  def create_general_daily_frequency(date, custom_classroom: classroom)
    create(
      :daily_frequency,
      classroom: custom_classroom,
      school_calendar: school_calendar,
      frequency_date: date,
      discipline_id: nil,
      class_number: nil
    )
  end

  # Frequência por disciplina: permite mais de um lançamento do mesmo aluno no mesmo dia
  def create_discipline_daily_frequency(date, class_number)
    create(
      :daily_frequency,
      classroom: classroom,
      discipline: discipline,
      school_calendar: school_calendar,
      frequency_date: date,
      class_number: class_number
    )
  end

  # Cria um AbsenceJustificationsStudent válido (respeitando FKs) para vincular a DailyFrequencyStudent
  # e faz o link manualmente no registro de frequência informado.
  def create_justified_absence_for(daily_frequency_student, absence_date)
    justification = AbsenceJustification.new(
      unity: classroom.unity,
      classroom: classroom,
      school_calendar: school_calendar,
      user: create(:user),
      teacher_id: create(:teacher).id,
      absence_date: absence_date,
      absence_date_end: absence_date,
      justification: 'Atestado'
    )
    justification.save(validate: false)

    AbsenceJustificationsStudent.skip_callback(:save, :after, :justify_old_absences)
    ajs = AbsenceJustificationsStudent.create!(
      student: daily_frequency_student.student,
      absence_justification: justification
    )
    AbsenceJustificationsStudent.set_callback(:save, :after, :justify_old_absences)

    daily_frequency_student.update_column(:absence_justification_student_id, ajs.id)
    ajs
  end

  describe '.call' do
    context 'when the day has at least one presence among the records' do
      before do
        daily_frequency = create_discipline_daily_frequency(monday, 1)
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)

        other_daily_frequency = create_discipline_daily_frequency(monday, 2)
        create(:daily_frequency_student, daily_frequency: other_daily_frequency, student: student, present: false)
      end

      it 'returns presence for the day' do
        expect(call_service).to eq(monday.iso8601 => 'presence')
      end
    end

    context 'when the day has only absences and all of them are justified' do
      before do
        daily_frequency = create_general_daily_frequency(monday)
        absence = create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: false)
        create_justified_absence_for(absence, monday)
      end

      it 'returns justified for the day' do
        expect(call_service).to eq(monday.iso8601 => 'justified')
      end
    end

    context 'when the day has absences and only part of them are justified' do
      before do
        daily_frequency = create_discipline_daily_frequency(monday, 1)
        justified = create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: false)
        create_justified_absence_for(justified, monday)

        other_daily_frequency = create_discipline_daily_frequency(monday, 2)
        create(:daily_frequency_student, daily_frequency: other_daily_frequency, student: student, present: false)
      end

      it 'returns absent for the day' do
        expect(call_service).to eq(monday.iso8601 => 'absent')
      end
    end

    context 'when the day has only unjustified absences' do
      before do
        daily_frequency = create_general_daily_frequency(monday)
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: false)
      end

      it 'returns absent for the day' do
        expect(call_service).to eq(monday.iso8601 => 'absent')
      end
    end

    context 'when the day has inactive records' do
      before do
        daily_frequency = create_discipline_daily_frequency(monday, 1)
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student: student,
          present: true,
          active: false
        )

        other_daily_frequency = create_discipline_daily_frequency(monday, 2)
        create(:daily_frequency_student, daily_frequency: other_daily_frequency, student: student, present: false)
      end

      it 'ignores inactive records when classifying the day' do
        expect(call_service).to eq(monday.iso8601 => 'absent')
      end
    end

    context 'when the day has only inactive records' do
      before do
        daily_frequency = create_general_daily_frequency(monday)
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student: student,
          present: true,
          active: false
        )
      end

      it 'does not include the day in the result' do
        expect(call_service).to eq({})
      end
    end

    context 'when records exist outside the requested period' do
      before do
        inside_frequency = create_general_daily_frequency(monday)
        create(:daily_frequency_student, daily_frequency: inside_frequency, student: student, present: true)

        outside_frequency = create_general_daily_frequency(Date.new(year, 4, 1))
        create(:daily_frequency_student, daily_frequency: outside_frequency, student: student, present: false)
      end

      it 'includes only days within start_at and end_at' do
        expect(call_service).to eq(monday.iso8601 => 'presence')
      end
    end

    context 'when records exist outside the enrollment classroom period' do
      let(:student_enrollment_classroom) do
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          joined_at: '2026-03-03',
          left_at: '2026-03-04'
        )
      end

      before do
        before_joining = create_general_daily_frequency(monday)
        create(:daily_frequency_student, daily_frequency: before_joining, student: student, present: true)

        while_joined = create_general_daily_frequency(tuesday)
        create(:daily_frequency_student, daily_frequency: while_joined, student: student, present: true)

        after_leaving = create_general_daily_frequency(wednesday)
        create(:daily_frequency_student, daily_frequency: after_leaving, student: student, present: true)
      end

      it 'includes only days between joined_at (inclusive) and left_at (exclusive)' do
        expect(call_service).to eq(tuesday.iso8601 => 'presence')
      end
    end

    context 'when do_not_send_justified_absence is enabled' do
      before do
        daily_frequency = create_general_daily_frequency(monday)
        absence = create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: false)
        create_justified_absence_for(absence, monday)

        GeneralConfiguration.first || GeneralConfiguration.create!
        GeneralConfiguration.first.update!(do_not_send_justified_absence: true)
      end

      after { GeneralConfiguration.first.update!(do_not_send_justified_absence: false) }

      it 'still returns justified as a distinct status' do
        expect(call_service).to eq(monday.iso8601 => 'justified')
      end
    end

    context 'when multiple days have records' do
      before do
        [monday, tuesday, wednesday].each_with_index do |date, index|
          daily_frequency = create_general_daily_frequency(date)
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: student,
            present: index != 1
          )
        end
      end

      it 'returns ISO 8601 string keys ordered by most recent date first' do
        result = call_service

        expect(result.keys).to eq([wednesday.iso8601, tuesday.iso8601, monday.iso8601])
        expect(result).to eq(
          monday.iso8601 => 'presence',
          tuesday.iso8601 => 'absent',
          wednesday.iso8601 => 'presence'
        )
      end
    end

    context 'when start_at and end_at are not given' do
      before do
        [Date.new(year, 2, 2), monday, Date.new(year, 4, 1)].each do |date|
          daily_frequency = create_general_daily_frequency(date)
          create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)
        end
      end

      it 'returns every day with records, most recent first' do
        result = described_class.call(student_enrollment_api_code: student_enrollment.api_code)

        expect(result.keys).to eq(['2026-04-01', monday.iso8601, '2026-02-02'])
        expect(result.values.uniq).to eq(['presence'])
      end
    end

    context 'when limit is given' do
      before do
        [monday, tuesday, wednesday].each do |date|
          daily_frequency = create_general_daily_frequency(date)
          create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)
        end
      end

      it 'returns only the most recent days up to the limit' do
        result = described_class.call(
          student_enrollment_api_code: student_enrollment.api_code,
          limit: 2
        )

        expect(result).to eq(
          wednesday.iso8601 => 'presence',
          tuesday.iso8601 => 'presence'
        )
      end
    end

    context 'when only start_at is given' do
      before do
        [Date.new(year, 2, 2), monday].each do |date|
          daily_frequency = create_general_daily_frequency(date)
          create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)
        end
      end

      it 'returns only days from start_at on' do
        result = described_class.call(
          student_enrollment_api_code: student_enrollment.api_code,
          start_at: start_at
        )

        expect(result).to eq(monday.iso8601 => 'presence')
      end
    end

    context 'when the enrollment api_code does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { call_service(api_code: 'INEXISTENT') }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the period has no records' do
      it 'returns an empty hash' do
        expect(call_service).to eq({})
      end
    end

    context 'when the student has frequencies in a classroom not linked to the enrollment' do
      let(:other_classroom) { create(:classroom, year: year, api_code: '002', unity: classroom.unity) }

      before do
        daily_frequency = create_general_daily_frequency(monday, custom_classroom: other_classroom)
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: false)
      end

      it 'does not include days from the unlinked classroom' do
        expect(call_service).to eq({})
      end
    end
  end
end
