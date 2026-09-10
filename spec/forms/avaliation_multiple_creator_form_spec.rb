# frozen_string_literal: true

require 'rails_helper'

# A tela de múltiplas turmas tem campos únicos no topo (Descrição, Peso) e uma linha por turma.
# As validações que dependem da turma vivem na Avaliation, e este formulário decide onde cada
# mensagem aparece: no campo do topo ou na linha da turma.
RSpec.describe AvaliationMultipleCreatorForm, type: :form do
  let(:classroom) { create(:classroom) }
  let(:discipline) { create(:discipline) }
  let(:teacher) { create(:teacher) }
  let(:school_calendar) { create(:school_calendar, :with_one_step, unity: classroom.unity) }
  let(:grade) do
    create(:school_calendar_discipline_grade, school_calendar: school_calendar,
                                              discipline: discipline).grade
  end

  let!(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom, teacher: teacher, discipline: discipline,
                                          classroom: classroom)
  end
  # Já existe uma configuração semeada para o ano corrente, e o ano é único em test_settings.
  let(:test_setting) do
    TestSetting.find_or_initialize_by(year: classroom.year).tap do |setting|
      setting.update!(
        exam_setting_type: ExamSettingTypes::GENERAL,
        maximum_score: 10,
        number_of_decimal_places: 1,
        average_calculation_type: AverageCalculationTypes::ARITHMETIC_AND_SUM
      )
    end
  end

  def build_form(test_date:, weight:, test_setting_id: test_setting.id)
    described_class.new(
      'unity_id' => classroom.unity_id,
      'discipline_id' => discipline.id,
      'school_calendar_id' => school_calendar.id,
      'test_setting_id' => test_setting_id,
      'description' => 'Prova',
      'weight' => weight,
      'avaliations_attributes' => {
        '0' => {
          'include' => '1',
          'classroom_id' => classroom.id.to_s,
          'test_date' => test_date,
          'grade_ids' => grade.id.to_s
        }
      },
      teacher_id: teacher.id
    )
  end

  # Cada turma marcada aponta o próprio erro: o laço acumula as mensagens no :base do formulário e
  # a segunda turma não pode sair em branco por causa disso.
  it 'shows the weight error on every selected classroom' do
    other_classroom = create(:classroom, unity: classroom.unity)
    create(:teacher_discipline_classroom, teacher: teacher, discipline: discipline,
                                          classroom: other_classroom)

    form = described_class.new(
      'unity_id' => classroom.unity_id,
      'discipline_id' => discipline.id,
      'school_calendar_id' => school_calendar.id,
      'test_setting_id' => test_setting.id,
      'description' => 'Prova',
      'weight' => '101',
      'avaliations_attributes' => {
        '0' => { 'include' => '1', 'classroom_id' => classroom.id.to_s,
                 'test_date' => '10/03/2026', 'grade_ids' => grade.id.to_s },
        '1' => { 'include' => '1', 'classroom_id' => other_classroom.id.to_s,
                 'test_date' => '10/03/2026', 'grade_ids' => grade.id.to_s }
      },
      teacher_id: teacher.id
    )

    expect(form).not_to be_valid
    expect(form.avaliations.map { |avaliation| avaliation.errors[:classroom] })
      .to eq([['Peso não pode ser maior que 10'], ['Peso não pode ser maior que 10']])
  end

  # O peso é campo único do topo, mas quem sabe se ele cabe é a avaliação de cada turma.
  it 'shows the weight error of the avaliation on the classroom row' do
    form = build_form(test_date: '10/03/2026', weight: '101')

    expect(form).not_to be_valid
    expect(form.errors[:weight]).to be_empty
    expect(form.avaliations.first.errors[:classroom]).to eq(['Peso não pode ser maior que 10'])
  end

  context 'when the test type allows breaking up' do
    let(:breakable_test_setting) { create(:test_setting_with_sum_calculation_type_that_allow_break_up) }
    let(:breakable_test) { breakable_test_setting.tests.first }

    # Quanto ainda cabe depende do que já foi lançado naquela turma, então é a linha dela que diz.
    it 'shows on the classroom row the weight left for that classroom' do
      lancada = create(
        :avaliation,
        classroom: classroom,
        discipline: discipline,
        school_calendar: school_calendar,
        test_setting: breakable_test_setting,
        test_setting_test: breakable_test,
        test_date: Date.current,
        weight: breakable_test.weight - 1,
        teacher_id: teacher.id,
        grade_ids: [grade.id]
      )
      form = described_class.new(
        'unity_id' => classroom.unity_id,
        'discipline_id' => discipline.id,
        'school_calendar_id' => school_calendar.id,
        'test_setting_id' => breakable_test_setting.id,
        'test_setting_test_id' => breakable_test.id,
        'description' => 'Prova',
        'weight' => '2',
        'avaliations_attributes' => {
          '0' => { 'include' => '1', 'classroom_id' => classroom.id.to_s,
                   'test_date' => lancada.test_date.strftime('%d/%m/%Y'),
                   'grade_ids' => grade.id.to_s }
        },
        teacher_id: teacher.id
      )

      expect(form).not_to be_valid
      expect(form.errors[:weight]).to be_empty
      expect(form.avaliations.first.errors[:classroom]).to eq(['Peso deve ser menor ou igual a 1.0'])
    end
  end

  # Um campo do topo inválido não pode esconder o erro da linha da turma.
  it 'keeps the classroom errors when a form field is invalid' do
    form = build_form(test_date: '', weight: '5')
    form.description = ''

    expect(form).not_to be_valid
    expect(form.errors[:description]).to eq(['não pode ficar em branco'])
    expect(form.avaliations.first.errors[:test_date]).to be_present
  end

  # A validação de cada turma roda mesmo com o topo inválido, então precisa tolerar campo do topo vazio.
  it 'reports the blank test setting when a classroom is selected' do
    form = build_form(test_date: '10/03/2026', weight: '5', test_setting_id: '')

    expect(form).not_to be_valid
    expect(form.errors[:test_setting_id]).to eq(['não pode ficar em branco'])
  end

  it 'does not repeat the date error on the classroom row' do
    form = build_form(test_date: '', weight: '5')
    avaliation = form.avaliations.first

    expect(form).not_to be_valid
    expect(avaliation.errors[:test_date]).to be_present
    expect(avaliation.errors[:classroom].join).not_to include('Data')
  end
end
