require 'rails_helper'

# Reconstrói um PEI em memória a partir do snapshot de uma versão publicada, com os
# valores CONGELADOS (nomes do snapshot, ids sintéticos) — sem tocar no banco.
RSpec.describe IndividualizedEducationalPlanSnapshotRestorer, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:content) do
    {
      'identification' => {
        'student_name' => 'Aluno Teste', 'birth_date' => '01/01/2015',
        'guardians' => 'Mãe X', 'diagnosis' => 'TEA', 'shift' => 'Manhã',
        'unity_name' => 'Escola A', 'classroom_name' => 'Turma 1',
        'teacher_name' => 'Prof Regente', 'aee_teacher_name' => 'Prof AEE',
        'support_professional' => 'Apoio Y', 'year' => 2026,
        'elaborated_at' => '2026-02-01',
        'review_dates' => ['2026-04-01', '2026-08-01']
      },
      'characterization' => {
        'characterization' => 'Texto caracterizacao', 'potentialities' => 'Potencialidades',
        'communication_profile' => ['Verbal', 'Gestual'],
        'social_interaction_profile' => [], 'autonomy' => ['Autonomia parcial']
      },
      'support_team' => {
        'family_guidelines' => 'Orientacoes', 'accompaniment' => ['Fonoaudiologia'], 'support_type' => [],
        'uses_medication' => true, 'medication_notes' => 'Apos o almoco',
        'medications' => [
          { 'iep_medication_id' => 11, 'name' => 'Metilfenidato', 'dosage' => '10 mg', 'schedule' => '07h30' },
          { 'iep_medication_id' => 12, 'name' => 'Risperidona', 'dosage' => '1 mg', 'schedule' => '20h00' }
        ],
        'family_environment_characteristics' => 'Rotina estruturada'
      },
      'curricular_plannings' => [
        { 'review_number' => 1, 'review_date' => '2026-04-01',
          'component_type' => 'discipline', 'component_name' => 'Portugues',
          'long_term_goal' => 'Meta de longo prazo',
          'instructional_accommodations' => ['Tempo extra'],
          'environmental_accommodations' => [], 'assessment_accommodations' => [] }
      ],
      'periodic_evaluations' => [
        { 'review_number' => 2, 'review_date' => '2026-08-01',
          'component_type' => 'knowledge_area', 'component_name' => 'Linguagem',
          'acquired_skills' => 'Habilidades adquiridas' }
      ],
      'final_evaluation' => { 'annual_report' => 'Relatorio anual' }
    }
  end

  subject(:result) { described_class.restore(content) }

  it 'restores frozen scalar and display fields' do
    plan = result.plan

    expect(plan.characterization).to eq('Texto caracterizacao')
    expect(plan.annual_report).to eq('Relatorio anual')
    expect(plan.family_guidelines).to eq('Orientacoes')
    expect(plan.unity_name).to eq('Escola A')
    expect(plan.guardians).to eq('Mãe X')
    expect(plan.year).to eq(2026)
    expect(plan.elaborated_at).to eq(Date.new(2026, 2, 1))
  end

  it 'restores the medication and family environment frozen values' do
    plan = result.plan

    expect(plan.uses_medication).to eq(true)
    expect(plan.iep_medications.map { |medication| [medication.name, medication.dosage, medication.schedule] })
      .to eq([['Metilfenidato', '10 mg', '07h30'], ['Risperidona', '1 mg', '20h00']])
    expect(plan.iep_medications).to all(be_readonly)
    expect(plan.iep_medications.map(&:id)).to all(be_negative)
    expect(plan.medication_notes).to eq('Apos o almoco')
    expect(plan.family_environment_characteristics).to eq('Rotina estruturada')
  end

  # false congelado tem que voltar como false (resposta "Não"), não como campo vazio.
  it 'restores a frozen "no" medication answer' do
    content['support_team'] = { 'uses_medication' => false }

    expect(described_class.restore(content).plan.uses_medication).to eq(false)
  end

  it 'restores the single medication fields of an older snapshot as one medication' do
    content['support_team'] = { 'uses_medication' => nil, 'medication_name' => 'Medicamento A',
                                'medication_dosage' => '5mg', 'medication_schedule' => '08:00' }

    medications = described_class.restore(content).plan.iep_medications

    expect(medications.map { |medication| [medication.name, medication.dosage, medication.schedule] })
      .to eq([['Medicamento A', '5mg', '08:00']])
  end

  # Versão publicada antes de os campos existirem: as chaves ausentes viram nil, sem erro.
  it 'leaves the medication fields empty for a snapshot published before they existed' do
    content['support_team'] = { 'family_guidelines' => 'Orientacoes' }

    plan = described_class.restore(content).plan

    expect(plan.uses_medication).to be_nil
    expect(plan.iep_medications).to be_empty
    expect(plan.medication_notes).to be_nil
    expect(plan.family_environment_characteristics).to be_nil
    expect(plan.family_guidelines).to eq('Orientacoes')
  end

  it 'restores student and aee_teacher stand-ins with frozen names' do
    plan = result.plan

    expect(plan.student.name).to eq('Aluno Teste')
    expect(plan.aee_teacher.name).to eq('Prof AEE')
    expect(result.students.map(&:name)).to eq(['Aluno Teste'])
    expect(result.aee_teachers.map(&:name)).to eq(['Prof AEE'])
  end

  it 'restores review dates in order' do
    dates = result.plan.iep_review_dates.map(&:review_date)

    expect(dates).to eq([Date.new(2026, 4, 1), Date.new(2026, 8, 1)])
  end

  it 'restores section 2/3 options resolving names without hitting the database' do
    plan = result.plan
    comm_kind = IepOptionKinds::COMMUNICATION_PROFILE

    expect(plan.communication_profile_option_ids.size).to eq(2)
    expect(result.iep_options_by_kind[comm_kind].map(&:description)).to match_array(['Verbal', 'Gestual'])
    # Os ids selecionados têm de existir na coleção do select, senão o multi-select abre vazio.
    expect(plan.communication_profile_option_ids)
      .to match_array(result.iep_options_by_kind[comm_kind].map(&:id))
    expect(plan.accompaniment_option_ids.size).to eq(1)
  end

  it 'links section 4 line to its review and freezes discipline and accommodation' do
    plan = result.plan
    planning = plan.iep_curricular_plannings.first

    expect(planning.discipline.description).to eq('Portugues')
    expect(planning.knowledge_area).to be_nil
    expect(planning.iep_review_date_id).to eq(plan.iep_review_dates.first.id)
    expect(planning.instructional_accommodation_option_ids.size).to eq(1)
  end

  it 'links section 5 line to its review by knowledge area' do
    plan = result.plan
    evaluation = plan.iep_periodic_evaluations.first

    expect(evaluation.knowledge_area.description).to eq('Linguagem')
    expect(evaluation.discipline).to be_nil
    expect(evaluation.iep_review_date_id).to eq(plan.iep_review_dates.second.id)
  end

  it 'freezes every stand-in as readonly with negative synthetic ids' do
    plan = result.plan

    # readonly! impede um POST acidental (o form aponta para create); ids negativos nunca casam com PK real.
    expect(plan).to be_readonly
    expect(plan.student).to be_readonly
    expect(plan.iep_review_dates.first).to be_readonly
    expect(plan.iep_curricular_plannings.first).to be_readonly
    expect(plan.iep_review_dates.map(&:id)).to all(be_negative)
  end

  describe 'invalid snapshots' do
    it 'raises InvalidSnapshot when the minimum (student name) is missing' do
      expect { described_class.restore({}) }.to raise_error(described_class::InvalidSnapshot)
      expect { described_class.restore('identification' => { 'year' => 2026 }) }
        .to raise_error(described_class::InvalidSnapshot)
    end

    it 'raises InvalidSnapshot when a component line references an unresolved review' do
      broken = content.deep_dup
      broken['curricular_plannings'].first['review_number'] = 9 # não existe entre as review_dates

      expect { described_class.restore(broken) }.to raise_error(described_class::InvalidSnapshot)
    end
  end
end
