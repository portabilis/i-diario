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
  let(:student) { student_enrollment_classroom.student_enrollment.student }

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

    # Skip do callback justify_old_absences para evitar efeito colateral no spec:
    # queremos ligar só o registro específico, não varrer todo o período.
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

      it 'returns 90% frequency for a student with 2 absences out of 20 records' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [month]
        )

        expect(result.size).to eq(1)
        expect(result.first[:classroom_id]).to eq(classroom.api_code)
        expect(result.first[:year]).to eq(year)
        expect(result.first[:months].size).to eq(1)

        month_entry = result.first[:months].first
        expect(month_entry[:month]).to eq(month)
        expect(month_entry[:students].size).to eq(1)

        student_row = month_entry[:students].first
        expect(student_row[:student_id]).to eq(student.api_code)
        expect(student_row[:presences]).to eq(18)
        expect(student_row[:absences]).to eq(2)
        expect(student_row[:total_records]).to eq(20)
        expect(student_row[:frequency_percentage]).to eq(90.0)
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
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [3, 4, 5]
        )

        months = result.first[:months]
        expect(months.map { |m| m[:month] }).to eq([3, 4, 5])

        march = months.find { |m| m[:month] == 3 }
        april = months.find { |m| m[:month] == 4 }
        may = months.find { |m| m[:month] == 5 }

        expect(march[:students].first[:presences]).to eq(9)
        expect(march[:students].first[:absences]).to eq(1)
        expect(march[:students].first[:frequency_percentage]).to eq(90.0)

        expect(april[:students].first[:presences]).to eq(8)
        expect(april[:students].first[:absences]).to eq(2)
        expect(april[:students].first[:frequency_percentage]).to eq(80.0)

        expect(may[:students].first[:presences]).to eq(10)
        expect(may[:students].first[:absences]).to eq(0)
        expect(may[:students].first[:frequency_percentage]).to eq(100.0)
      end
    end

    context 'when a requested month has no records' do
      before do
        # Só lança chamada em março
        weekdays_in(year, 3, 5).each do |date|
          daily_frequency = create_general_daily_frequency(date)
          create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)
        end
      end

      it 'returns empty students list for months without records and populated list for months with records' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [3, 4]
        )

        months = result.first[:months]
        march = months.find { |m| m[:month] == 3 }
        april = months.find { |m| m[:month] == 4 }

        expect(march[:students].size).to eq(1)
        expect(march[:students].first[:total_records]).to eq(5)

        expect(april[:students]).to be_empty
      end
    end

    context 'when some school days have no attendance registered' do
      before do
        # 15 dias úteis lançados de 20 possíveis, 2 faltas
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
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [month]
        )

        student_row = result.first[:months].first[:students].first
        expect(student_row[:presences]).to eq(13)
        expect(student_row[:absences]).to eq(2)
        expect(student_row[:total_records]).to eq(15)
        expect(student_row[:frequency_percentage]).to eq(86.67)
      end
    end

    context 'when classroom uses FrequencyTypes::BY_DISCIPLINE (multiple records per day)' do
      let(:discipline) { create(:discipline) }

      before do
        # 4 dias úteis, 5 aulas por dia = 20 registros, 2 faltas
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
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [month]
        )

        student_row = result.first[:months].first[:students].first
        expect(student_row[:presences]).to eq(18)
        expect(student_row[:absences]).to eq(2)
        expect(student_row[:total_records]).to eq(20)
        expect(student_row[:frequency_percentage]).to eq(90.0)
      end
    end

    context 'when a transferred student has fewer attendance records' do
      let(:second_enrollment_classroom) do
        create(:student_enrollment_classroom, classrooms_grade: classrooms_grade, joined_at: '2026-02-01')
      end
      let(:second_student) { second_enrollment_classroom.student_enrollment.student }

      before do
        dates = weekdays_in(year, month, 20)

        dates.each_with_index do |date, index|
          daily_frequency = create_general_daily_frequency(date)

          # Aluno 1: participa todos os 20 dias, 2 faltas
          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: student,
            present: ![4, 10].include?(index)
          )

          # Aluno 2: só participa dos 10 primeiros dias (transferido depois), 1 falta
          next if index >= 10

          create(
            :daily_frequency_student,
            daily_frequency: daily_frequency,
            student: second_student,
            present: index != 3
          )
        end
      end

      it 'returns frequency calculated only over the days each student has records' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [month]
        )

        rows = result.first[:months].first[:students].index_by { |row| row[:student_id] }

        expect(rows[student.api_code][:total_records]).to eq(20)
        expect(rows[student.api_code][:frequency_percentage]).to eq(90.0)

        expect(rows[second_student.api_code][:total_records]).to eq(10)
        expect(rows[second_student.api_code][:presences]).to eq(9)
        expect(rows[second_student.api_code][:absences]).to eq(1)
        expect(rows[second_student.api_code][:frequency_percentage]).to eq(90.0)
      end
    end

    context 'when the student has no attendance records in the month' do
      it 'returns an empty students list for that month' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [month]
        )

        expect(result.first[:months].first[:students]).to be_empty
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
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [month]
        )

        expect(result.first[:months].first[:students]).to be_empty
      end
    end

    context 'when student_ids filter is provided' do
      let(:other_enrollment_classroom) do
        create(:student_enrollment_classroom, classrooms_grade: classrooms_grade, joined_at: '2026-02-01')
      end
      let(:other_student) { other_enrollment_classroom.student_enrollment.student }

      before do
        date = weekdays_in(year, month, 1).first
        daily_frequency = create_general_daily_frequency(date)
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: other_student, present: true)
      end

      it 'returns only the requested students' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [month],
          students_api_code: [student.api_code]
        )

        students = result.first[:months].first[:students]
        expect(students.size).to eq(1)
        expect(students.first[:student_id]).to eq(student.api_code)
      end
    end

    context 'when multiple classrooms are requested' do
      let(:other_classroom) { create(:classroom, year: year, api_code: '002', unity: classroom.unity) }
      let!(:other_classrooms_grade) { create(:classrooms_grade, classroom: other_classroom) }
      let(:other_enrollment_classroom) do
        create(:student_enrollment_classroom, classrooms_grade: other_classrooms_grade, joined_at: '2026-02-01')
      end
      let(:other_student) { other_enrollment_classroom.student_enrollment.student }

      before do
        date = weekdays_in(year, month, 1).first

        daily_frequency_a = create_general_daily_frequency(date)
        create(:daily_frequency_student, daily_frequency: daily_frequency_a, student: student, present: true)

        daily_frequency_b = create_general_daily_frequency(date, custom_classroom: other_classroom)
        create(:daily_frequency_student, daily_frequency: daily_frequency_b, student: other_student, present: false)
      end

      it 'returns one entry per classroom' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code, other_classroom.api_code],
          year: year,
          months: [month]
        )

        expect(result.size).to eq(2)
        expect(result.map { |r| r[:classroom_id] }).to match_array([classroom.api_code, other_classroom.api_code])

        first = result.find { |r| r[:classroom_id] == classroom.api_code }
        second = result.find { |r| r[:classroom_id] == other_classroom.api_code }

        expect(first[:months].first[:students].first[:frequency_percentage]).to eq(100.0)
        expect(second[:months].first[:students].first[:frequency_percentage]).to eq(0.0)
      end
    end

    context 'when students have records outside the requested months' do
      before do
        march_date = weekdays_in(year, 3, 1).first
        february_date = weekdays_in(year, 2, 1).first
        may_date = weekdays_in(year, 5, 1).first

        march_frequency = create_general_daily_frequency(march_date)
        create(:daily_frequency_student, daily_frequency: march_frequency, student: student, present: true)

        # Fevereiro (fora do range solicitado) - não pode entrar
        february_frequency = create_general_daily_frequency(february_date)
        create(:daily_frequency_student, daily_frequency: february_frequency, student: student, present: false)

        # Maio (fora do range solicitado, meses não contíguos) - não pode entrar
        may_frequency = create_general_daily_frequency(may_date)
        create(:daily_frequency_student, daily_frequency: may_frequency, student: student, present: false)
      end

      it 'aggregates only records within the requested months' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [3, 4]
        )

        march = result.first[:months].find { |m| m[:month] == 3 }
        april = result.first[:months].find { |m| m[:month] == 4 }

        expect(march[:students].first[:total_records]).to eq(1)
        expect(march[:students].first[:presences]).to eq(1)
        expect(march[:students].first[:frequency_percentage]).to eq(100.0)

        expect(april[:students]).to be_empty
      end
    end

    context 'when a student has only absences' do
      before do
        date = weekdays_in(year, month, 1).first
        daily_frequency = create_general_daily_frequency(date)
        create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: false)
      end

      it 'returns 0% frequency' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code],
          year: year,
          months: [month]
        )

        student_row = result.first[:months].first[:students].first
        expect(student_row[:presences]).to eq(0)
        expect(student_row[:absences]).to eq(1)
        expect(student_row[:total_records]).to eq(1)
        expect(student_row[:frequency_percentage]).to eq(0.0)
      end
    end

    context 'when no classroom matches the requested year' do
      it 'returns an empty array' do
        result = described_class.call(
          classrooms_api_code: [classroom.api_code],
          year: 2099,
          months: [month]
        )

        expect(result).to eq([])
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
            classrooms_api_code: [classroom.api_code],
            year: year,
            months: [month]
          )

          student_row = result.first[:months].first[:students].first
          expect(student_row[:presences]).to eq(18)
          expect(student_row[:absences]).to eq(2)
          expect(student_row[:total_records]).to eq(20)
          expect(student_row[:frequency_percentage]).to eq(90.0)
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
            classrooms_api_code: [classroom.api_code],
            year: year,
            months: [month]
          )

          student_row = result.first[:months].first[:students].first
          expect(student_row[:presences]).to eq(19)
          expect(student_row[:absences]).to eq(1)
          expect(student_row[:total_records]).to eq(20)
          expect(student_row[:frequency_percentage]).to eq(95.0)
        end
      end
    end
  end
end
