require 'rails_helper'

RSpec.describe Api::MonthlyFrequenciesService do
  include ActiveSupport::Testing::TimeHelpers

  before(:all) { travel_to Time.zone.local(2026, 6, 30, 12, 0, 0) }
  after(:all) { travel_back }

  let(:year) { 2026 }
  let(:month) { 3 }
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

  before do
    student_enrollment.update!(api_code: 'EN001') if student_enrollment.api_code.blank?
  end

  # Feriados nacionais inseridos pelo SchoolCalendarEventsSeeder
  SEEDED_HOLIDAYS = %w[01-01 04-21 05-01 09-07 10-12 11-02 11-15 12-25].freeze

  # Retorna os `count` primeiros dias letivos do mês informado (ignora fds e feriados nacionais)
  def weekdays_in(year, month, count)
    date = Date.new(year, month, 1)
    weekdays = []
    while weekdays.size < count
      is_weekend = [0, 6].include?(date.wday)
      is_holiday = SEEDED_HOLIDAYS.include?(date.strftime('%m-%d'))
      weekdays << date unless is_weekend || is_holiday
      date += 1
    end
    weekdays
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
    context 'when every school day has attendance registered (FrequencyTypes::GENERAL)' do
      before do
        # 20 dias úteis de março/2026 com chamada lançada, 2 faltas
        dates = weekdays_in(year, month, 20)
        absence_dates = [dates[4], dates[10]]

        dates.each do |date|
          daily_frequency = create_general_daily_frequency(date)
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: student,
            present: absence_dates.exclude?(date)
          )
        end
      end

      it 'returns 90% frequency for the enrollment with 2 absences out of 20 records' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code],
          months: [month]
        )

        expect(result.size).to eq(1)
        entry = result.first
        expect(entry[:course_name]).to eq(classrooms_grade.grade.course.description)
        expect(entry[:student_enrollment_id]).to eq(student_enrollment.api_code)
        expect(entry[:student_name]).to eq(student.name)
        expect(entry[:months]).to eq(month => 90.0)
      end
    end

    context 'when multiple months are requested (bimestre)' do
      before do
        # Março: 10 dias lançados, 1 falta
        weekdays_in(year, 3, 10).each_with_index do |date, index|
          daily_frequency = create_general_daily_frequency(date)
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: student,
            present: index != 2
          )
        end

        # Abril: 10 dias lançados, 2 faltas
        weekdays_in(year, 4, 10).each_with_index do |date, index|
          daily_frequency = create_general_daily_frequency(date)
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: student,
            present: ![1, 4].include?(index)
          )
        end

        # Maio: 10 dias lançados, 0 faltas
        weekdays_in(year, 5, 10).each do |date|
          daily_frequency = create_general_daily_frequency(date)
          create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)
        end
      end

      it 'returns one entry per month with independent aggregation' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code],
          months: [3, 4, 5]
        )

        expect(result.first[:months]).to eq(3 => 90.0, 4 => 80.0, 5 => 100.0)
      end
    end

    context 'when some school days have no attendance registered' do
      before do
        dates = weekdays_in(year, month, 15)
        absence_dates = [dates[3], dates[9]]

        dates.each do |date|
          daily_frequency = create_general_daily_frequency(date)
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: student,
            present: absence_dates.exclude?(date)
          )
        end
      end

      it 'calculates percentage only over days with registered attendance' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code],
          months: [month]
        )

        expect(result.first[:months][month]).to eq(86.67)
      end
    end

    context 'when classroom uses FrequencyTypes::BY_DISCIPLINE (multiple records per day)' do
      let(:discipline) { create(:discipline) }

      before do
        dates = weekdays_in(year, month, 4)

        dates.each_with_index do |date, day_index|
          (1..5).each do |class_number|
            daily_frequency = create(
              :daily_frequency,
              classroom: classroom,
              discipline: discipline,
              school_calendar: school_calendar,
              frequency_date: date,
              class_number: class_number
            )
            absent = (day_index == 0 && class_number == 1) || (day_index == 1 && class_number == 3)
            create(
              :daily_frequency_student,
              daily_frequency: daily_frequency,
              student: student,
              present: !absent
            )
          end
        end
      end

      it 'counts each class record independently' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code],
          months: [month]
        )

        expect(result.first[:months][month]).to eq(90.0)
      end
    end

    context 'when an enrollment has no records but is part of the requested ids' do
      it 'returns the enrollment with frequency_percentage=null in each month' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code],
          months: [month]
        )

        expect(result.size).to eq(1)
        expect(result.first[:student_enrollment_id]).to eq(student_enrollment.api_code)
        expect(result.first[:months][month]).to be_nil
      end
    end

    context 'when daily_frequency_students are inactive' do
      before do
        date = weekdays_in(year, month, 1).first
        daily_frequency = create_general_daily_frequency(date)
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student: student,
          present: true,
          active: false
        )
      end

      it 'ignores records with active = false' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code],
          months: [month]
        )

        expect(result.first[:months][month]).to be_nil
      end
    end

    context 'when multiple enrollments are requested' do
      let(:other_enrollment_classroom) do
        create(:student_enrollment_classroom, classrooms_grade: classrooms_grade, joined_at: '2026-02-01')
      end
      let(:other_enrollment) { other_enrollment_classroom.student_enrollment }
      let(:other_student) { other_enrollment.student }

      before do
        other_enrollment.update!(api_code: 'EN002')

        date = weekdays_in(year, month, 1).first
        daily_frequency = create_general_daily_frequency(date)
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: other_student, present: false)
      end

      it 'returns one entry per enrollment with course info on each item' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code, other_enrollment.api_code],
          months: [month]
        )

        expect(result.size).to eq(2)
        expect(result.map { |r| r[:student_enrollment_id] }).to match_array(
          [student_enrollment.api_code, other_enrollment.api_code]
        )
        # Course info repete em ambos (mesma classrooms_grade)
        expect(result.map { |r| r[:course_name] }.uniq).to eq([classrooms_grade.grade.course.description])

        entry_first = result.find { |r| r[:student_enrollment_id] == student_enrollment.api_code }
        entry_other = result.find { |r| r[:student_enrollment_id] == other_enrollment.api_code }

        expect(entry_first[:months][month]).to eq(100.0)
        expect(entry_other[:months][month]).to eq(0.0)
      end
    end

    context 'when an enrollment_id does not exist' do
      it 'silently ignores the missing enrollment' do
        result = described_class.call(
          student_enrollment_api_code:[student_enrollment.api_code, 'INEXISTENT'],
          months: [month]
        )

        expect(result.size).to eq(1)
        expect(result.first[:student_enrollment_id]).to eq(student_enrollment.api_code)
      end
    end

    context 'when no enrollment matches the requested ids' do
      it 'returns an empty array' do
        result = described_class.call(
          student_enrollment_api_code:['INEXISTENT_1', 'INEXISTENT_2'],
          months: [month]
        )

        expect(result).to eq([])
      end
    end

    context 'when enrollment has multiple classrooms (e.g., regular + contraturno)' do
      let(:second_classroom) { create(:classroom, year: year, api_code: '002', unity: classroom.unity) }
      let!(:second_classrooms_grade) { create(:classrooms_grade, classroom: second_classroom) }
      let!(:second_enrollment_classroom) do
        create(
          :student_enrollment_classroom,
          classrooms_grade: second_classrooms_grade,
          student_enrollment: student_enrollment,
          joined_at: '2026-02-01'
        )
      end

      before do
        # Turma 1 (regular): 5 dias, 1 falta
        weekdays_in(year, month, 5).each_with_index do |date, index|
          daily_frequency = create_general_daily_frequency(date)
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: student,
            present: index != 0
          )
        end

        # Turma 2 (contraturno): 5 dias, 0 faltas
        weekdays_in(year, month, 5).each do |date|
          daily_frequency = create_general_daily_frequency(date, custom_classroom: second_classroom)
          create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)
        end
      end

      it 'sums frequency from all classrooms linked to the enrollment' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code],
          months: [month]
        )

        expect(result.first[:months][month]).to eq(90.0)
      end
    end

    context 'when records exist outside the requested months' do
      before do
        march_date = weekdays_in(year, 3, 1).first
        february_date = weekdays_in(year, 2, 1).first
        may_date = weekdays_in(year, 5, 1).first

        march_frequency = create_general_daily_frequency(march_date)
        create(:daily_frequency_student, daily_frequency: march_frequency, student: student, present: true)

        february_frequency = create_general_daily_frequency(february_date)
        create(:daily_frequency_student, daily_frequency: february_frequency, student: student, present: false)

        may_frequency = create_general_daily_frequency(may_date)
        create(:daily_frequency_student, daily_frequency: may_frequency, student: student, present: false)
      end

      it 'aggregates only records within the requested months' do
        result = described_class.call(
          student_enrollment_api_code: [student_enrollment.api_code],
          months: [3, 4]
        )

        expect(result.first[:months]).to eq(3 => 100.0, 4 => nil)
      end
    end

    context 'with justified absences' do
      let(:dates) { weekdays_in(year, month, 20) }
      let(:justified_absence_date) { dates[4] }
      let(:unjustified_absence_date) { dates[10] }
      let!(:justified_daily_frequency_student) do
        justified = nil

        dates.each do |date|
          daily_frequency = create_general_daily_frequency(date)
          present = ![justified_absence_date, unjustified_absence_date].include?(date)

          dfs = create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: student,
            present: present
          )

          justified = dfs if date == justified_absence_date
        end

        create_justified_absence_for(justified, justified_absence_date)
        justified
      end

      context 'when do_not_send_justified_absence is disabled (default)' do
        before { GeneralConfiguration.first&.update!(do_not_send_justified_absence: false) }

        it 'counts justified absences as absences' do
          result = described_class.call(
            student_enrollment_api_code: [student_enrollment.api_code],
            months: [month]
          )

          expect(result.first[:months][month]).to eq(90.0)
        end
      end

      context 'when do_not_send_justified_absence is enabled' do
        before do
          GeneralConfiguration.first || GeneralConfiguration.create!
          GeneralConfiguration.first.update!(do_not_send_justified_absence: true)
        end

        after { GeneralConfiguration.first.update!(do_not_send_justified_absence: false) }

        it 'counts justified absences as presences' do
          result = described_class.call(
            student_enrollment_api_code: [student_enrollment.api_code],
            months: [month]
          )

          expect(result.first[:months][month]).to eq(95.0)
        end
      end
    end
  end
end
