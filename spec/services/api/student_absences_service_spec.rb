require 'rails_helper'

RSpec.describe Api::StudentAbsencesService do
  include ActiveSupport::Testing::TimeHelpers

  # O ambiente de teste desloca o relógio para 2017 (Timecop.travel em
  # config/environments/test.rb); as datas do exemplo são de 2026, e lançar
  # falta exige data não futura dentro do calendário letivo.
  before(:all) { travel_to Time.zone.local(2026, 7, 2, 0, 0, 0) }
  after(:all) { travel_back }

  let(:year) { 2026 }
  let(:unity) { create(:unity, api_code: 'unity-1') }
  let(:classroom) { create(:classroom, unity: unity, year: year) }
  let(:school_calendar) { create(:school_calendar, year: year, unity_id: unity.id) }
  let!(:school_calendar_step) do
    create(
      :school_calendar_step,
      school_calendar: school_calendar,
      step_number: 1,
      start_at: '2026-02-02',
      end_at: '2026-12-12'
    )
  end
  let(:student) { create(:student, api_code: '777') }
  let(:start_at) { Date.new(2026, 6, 1) }
  let(:end_at) { Date.new(2026, 6, 30) }

  let(:other_unity) { create(:unity, api_code: 'unity-2') }
  let(:unities) { [unity] }

  subject(:result) { described_class.call(unities: unities, start_at: start_at, end_at: end_at) }

  # O dia consolidado é o que o motor de infrequência enxerga.
  def consolidate(date, present:, student:, classroom: self.classroom)
    create(
      :unique_daily_frequency_student,
      student: student,
      classroom: classroom,
      frequency_date: date,
      present: present
    )
  end

  # O lançamento do diário: é nele que a justificativa se prende (a coluna é o
  # vínculo; o model não declara associação).
  def entry(date, student:, justified: false, active: true)
    daily_frequency = create(:daily_frequency, classroom: classroom, frequency_date: date)
    justification = justified ? create(:absence_justifications_student, student: student) : nil

    create(
      :daily_frequency_student,
      daily_frequency: daily_frequency,
      student: student,
      present: false,
      active: active,
      absence_justification_student_id: justification&.id
    )
  end

  def absences_of(student_api_code)
    result.find { |item| item[:student_api_code] == student_api_code }[:absences]
  end

  it 'reports how many entries of the day carry a justification' do
    consolidate('2026-06-10', present: false, student: student)
    entry('2026-06-10', student: student, justified: true)
    entry('2026-06-10', student: student)

    consolidate('2026-06-11', present: false, student: student)
    entry('2026-06-11', student: student)

    expect(result).to eq(
      [
        {
          student_api_code: '777',
          classroom_api_code: classroom.api_code,
          unity_api_code: 'unity-1',
          absences: [
            { date: '2026-06-10', entries_count: 2, justified_entries_count: 1 },
            { date: '2026-06-11', entries_count: 1, justified_entries_count: 0 }
          ]
        }
      ]
    )
  end

  it 'lists the days of a student in ascending order' do
    consolidate('2026-06-20', present: false, student: student)
    consolidate('2026-06-05', present: false, student: student)
    consolidate('2026-06-12', present: false, student: student)

    expect(absences_of('777').map { |absence| absence[:date] }).to eq(%w[2026-06-05 2026-06-12 2026-06-20])
  end

  # A regra do produto de origem: o dia consolidado manda. Se ele fechou como
  # presente, o dia não é falta aqui — mesmo havendo falta numa aula solta.
  it 'ignores a day that consolidated as present even with an absent entry' do
    consolidate('2026-06-12', present: true, student: student)
    entry('2026-06-12', student: student)

    expect(result).to be_empty
  end

  # A consolidação só olha lançamentos ativos; o lançamento de quem já saiu da
  # turma fica com `present` nulo e não pode entrar na contagem do dia.
  it 'does not count an inactive entry' do
    consolidate('2026-06-10', present: false, student: student)
    entry('2026-06-10', student: student)
    entry('2026-06-10', student: student, active: false)

    expect(absences_of('777')).to eq([{ date: '2026-06-10', entries_count: 1, justified_entries_count: 0 }])
  end

  it 'reports zero when the consolidated day has no diary entry' do
    consolidate('2026-06-10', present: false, student: student)

    expect(absences_of('777')).to eq([{ date: '2026-06-10', entries_count: 0, justified_entries_count: 0 }])
  end

  # Estudante cadastrado localmente não tem api_code; dois deles na mesma turma
  # são duas pessoas, não uma entrada com as faltas somadas.
  it 'keeps two students without api_code apart' do
    first_local = create(:student, api: false, api_code: nil)
    second_local = create(:student, api: false, api_code: nil)

    consolidate('2026-06-10', present: false, student: first_local)
    consolidate('2026-06-11', present: false, student: second_local)

    expect(result.size).to eq(2)
    expect(result.map { |item| item[:student_api_code] }).to eq([nil, nil])
    expect(result.map { |item| item[:absences].size }).to eq([1, 1])
    expect(result.flat_map { |item| item[:absences].map { |a| a[:date] } })
      .to match_array(%w[2026-06-10 2026-06-11])
  end

  it 'ignores days outside the period' do
    consolidate('2026-05-20', present: false, student: student)
    entry('2026-05-20', student: student)

    expect(result).to be_empty
  end

  it 'keeps only the absences of the requested unity' do
    other_classroom = create(:classroom, unity: other_unity, year: year)
    consolidate('2026-06-10', present: false, student: create(:student, api_code: 'theirs'), classroom: other_classroom)

    consolidate('2026-06-10', present: false, student: student)
    entry('2026-06-10', student: student)

    expect(result.map { |item| item[:student_api_code] }).to eq(['777'])
  end

  context 'with more than one unity' do
    let(:unities) { [unity, other_unity] }

    it 'returns the absences of every requested unity, each with its own api_code' do
      other_classroom = create(:classroom, unity: other_unity, year: year)
      consolidate('2026-06-10', present: false, student: create(:student, api_code: 'theirs'),
                                classroom: other_classroom)
      consolidate('2026-06-10', present: false, student: student)

      expect(result.map { |item| [item[:student_api_code], item[:unity_api_code]] })
        .to match_array([%w[777 unity-1], %w[theirs unity-2]])
    end
  end
end
