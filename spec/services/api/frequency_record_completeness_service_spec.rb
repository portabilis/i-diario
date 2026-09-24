require 'rails_helper'

RSpec.describe Api::FrequencyRecordCompletenessService do
  include ActiveSupport::Testing::TimeHelpers

  # O ambiente de teste desloca o relógio para 2017 (Timecop.travel em
  # config/environments/test.rb); as datas do exemplo são de 2026, e lançar
  # frequência exige data dentro do calendário letivo.
  before(:all) { travel_to Time.zone.local(2026, 7, 2, 0, 0, 0) }
  after(:all) { travel_back }

  let(:unity) { create(:unity, api_code: 'unity-1') }
  let(:classroom) { create(:classroom, unity: unity, year: 2026) }
  let(:school_calendar) { create(:school_calendar, year: 2026, unity_id: unity.id) }
  let!(:school_calendar_step) do
    create(
      :school_calendar_step,
      school_calendar: school_calendar,
      step_number: 1,
      start_at: '2026-02-02',
      end_at: '2026-12-12'
    )
  end
  let(:start_at) { Date.new(2026, 6, 1) }
  let(:end_at) { Date.new(2026, 6, 30) }

  let(:other_unity) { create(:unity, api_code: 'unity-2') }
  let(:unities) { [unity] }

  subject(:result) { described_class.call(unities: unities, start_at: start_at, end_at: end_at) }

  def school_days(*dates, unity: self.unity)
    dates.each { |date| create(:unity_school_day, unity: unity, school_day: date) }
  end

  def row_of(classroom)
    result.find { |item| item[:classroom_api_code] == classroom.api_code }
  end

  it 'counts the school days of the unity and the days the classroom recorded' do
    school_days('2026-06-01', '2026-06-02', '2026-06-03')

    # Duas disciplinas no mesmo dia contam UM dia com registro.
    create(:daily_frequency, classroom: classroom, frequency_date: '2026-06-01')
    create(:daily_frequency, classroom: classroom, frequency_date: '2026-06-01')
    create(:daily_frequency, classroom: classroom, frequency_date: '2026-06-02')

    expect(result).to eq(
      [
        {
          classroom_api_code: classroom.api_code,
          classroom_name: classroom.description,
          unity_api_code: 'unity-1',
          school_days: 3,
          days_with_record: 2,
          active_enrollments: 0
        }
      ]
    )
  end

  # A turma que nunca lançou é justamente a que o indicador existe para
  # mostrar: ela entra na lista com zero, nunca desaparece.
  it 'keeps a classroom that never recorded, with zero' do
    school_days('2026-06-01')
    classroom

    expect(row_of(classroom)).to include(days_with_record: 0, school_days: 1)
  end

  it 'ignores classrooms and school days of other unities' do
    other_classroom = create(:classroom, unity: other_unity, year: 2026)
    school_days('2026-06-01', unity: other_unity)
    classroom

    expect(result.map { |item| item[:classroom_api_code] }).to eq([classroom.api_code])
    expect(row_of(classroom)[:school_days]).to eq(0)
    expect(row_of(other_classroom)).to be_nil
  end

  # Turma é do ano letivo: no período que cruza o ano, cada turma recebe os
  # dias letivos do seu próprio ano — nem some, nem herda os dias do outro.
  context 'when the period crosses the school year' do
    let(:start_at) { Date.new(2025, 12, 1) }
    let(:end_at) { Date.new(2026, 2, 28) }

    it 'lists the classrooms of both years, each with the school days of its own year' do
      previous_classroom = create(:classroom, unity: unity, year: 2025)
      school_days('2025-12-01', '2025-12-02', '2026-02-02', '2026-02-03', '2026-02-04')
      classroom

      expect(row_of(previous_classroom)[:school_days]).to eq(2)
      expect(row_of(classroom)[:school_days]).to eq(3)
    end
  end

  # Unidade desconhecida chega aqui como lista vazia (a fronteira não trata
  # como erro): a resposta é a coleção vazia, nunca as turmas de outra escola.
  context 'without any unity' do
    let(:unities) { [] }

    it 'returns an empty collection' do
      school_days('2026-06-01')
      classroom

      expect(result).to eq([])
    end
  end

  # O denominador é o calendario da unidade DA TURMA: numa consulta com duas
  # escolas, uma nao pode herdar os dias letivos da outra.
  context 'with more than one unity' do
    let(:unities) { [unity, other_unity] }

    it 'gives each classroom the school days of its own unity' do
      other_classroom = create(:classroom, unity: other_unity, year: 2026)
      school_days('2026-06-01', '2026-06-02')
      school_days('2026-06-01', '2026-06-02', '2026-06-03', unity: other_unity)
      classroom

      expect(row_of(classroom)).to include(unity_api_code: 'unity-1', school_days: 2)
      expect(row_of(other_classroom)).to include(unity_api_code: 'unity-2', school_days: 3)
    end
  end

  describe 'active_enrollments' do
    let!(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }

    def enroll(classrooms_grade:, joined_at:, left_at: '', student_enrollment: create(:student_enrollment))
      create(
        :student_enrollment_classroom,
        student_enrollment: student_enrollment,
        classrooms_grade: classrooms_grade,
        joined_at: joined_at,
        left_at: left_at
      )
    end

    it 'counts the enrollments in force on some day of the period' do
      enroll(classrooms_grade: classrooms_grade, joined_at: '2026-02-01')
      enroll(classrooms_grade: classrooms_grade, joined_at: '2026-06-15', left_at: '2026-06-20')

      expect(row_of(classroom)[:active_enrollments]).to eq(2)
    end

    it 'ignores enrollments that left before or joined after the period' do
      enroll(classrooms_grade: classrooms_grade, joined_at: '2026-02-01', left_at: '2026-05-30')
      enroll(classrooms_grade: classrooms_grade, joined_at: '2026-07-01')
      enroll(classrooms_grade: classrooms_grade, joined_at: '2026-02-01').update_column(:discarded_at, Time.current)

      expect(row_of(classroom)[:active_enrollments]).to eq(0)
    end

    # Turma multisseriada tem um classrooms_grade por série; a mesma matrícula
    # enturmada nas duas é uma pessoa, não duas.
    it 'counts an enrollment once in a multi-grade classroom' do
      other_grade = create(:classrooms_grade, classroom: classroom)
      student_enrollment = create(:student_enrollment)

      enroll(classrooms_grade: classrooms_grade, joined_at: '2026-02-01', student_enrollment: student_enrollment)
      enroll(classrooms_grade: other_grade, joined_at: '2026-02-01', student_enrollment: student_enrollment)

      expect(row_of(classroom)[:active_enrollments]).to eq(1)
    end
  end
end
