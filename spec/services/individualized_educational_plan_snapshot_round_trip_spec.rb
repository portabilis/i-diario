require 'rails_helper'

# Contrato produtor↔consumidor: o que o Snapshot grava é exatamente o que o Restorer lê.
# Publica um plano real e reconstrói a versão — renomear uma chave num dos lados passa a
# quebrar este teste, em vez de silenciosamente abrir a versão em branco em produção.
RSpec.describe 'PEI snapshot round-trip', type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  before do
    allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
    allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
  end

  def publish_and_restore(plan)
    version = IndividualizedEducationalPlanPublisher.publish!(plan, name: 'Versão 1',
                                                              published_by: create(:user), classroom: create(:classroom))
    IndividualizedEducationalPlanSnapshotRestorer.restore(version.reload.content).plan
  end

  it 'restores the same frozen values that were published' do
    plan = create(:individualized_educational_plan, characterization: 'Perfil do aluno')
    review_date = create(:iep_review_date, iep: plan, review_date: Date.current)
    discipline = create(:discipline, description: 'Matemática')
    accommodation = create(:iep_option, :instructional_accommodation, description: 'Materiais concretos')
    planning = create(:iep_curricular_planning, iep: plan, iep_review_date: review_date,
                                                discipline: discipline, long_term_goal: 'Meta anual')
    planning.instructional_accommodation_option_ids = [accommodation.id]
    planning.save!

    restored = publish_and_restore(plan)

    expect(restored.student.name).to eq(plan.student.name)
    expect(restored.characterization).to eq('Perfil do aluno')
    expect(restored.iep_review_dates.map(&:review_date)).to eq([Date.current])

    restored_planning = restored.iep_curricular_plannings.first
    expect(restored_planning.discipline.description).to eq('Matemática')
    expect(restored_planning.long_term_goal).to eq('Meta anual')
    expect(restored_planning.iep_review_date_id).to eq(restored.iep_review_dates.first.id)
    expect(restored_planning.instructional_accommodation_option_ids.size).to eq(1)
  end

  # uses_medication: false atravessa publish (slice) → jsonb → restore como resposta "Não";
  # perder o false em qualquer um dos lados apagaria a resposta do documento imutável.
  it 'restores the frozen support team fields including a "no" medication answer' do
    plan = create(:individualized_educational_plan,
                  uses_medication: false, medication_name: 'Medicamento A',
                  medication_dosage: '5mg', medication_schedule: '08:00',
                  medication_notes: 'Apos o almoco',
                  family_environment_characteristics: 'Rotina estruturada')

    restored = publish_and_restore(plan)

    # No jsonb o false tem que ser BOOLEANO: uma string "false" é truthy para quem ler o conteúdo
    # bruto do documento imutável (o cast do plano restaurado esconderia essa diferença).
    frozen = plan.iep_versions.find_by(active: true).content['support_team']['uses_medication']
    expect(frozen).to eq(false)

    expect(restored.uses_medication).to eq(false)
    expect(restored.medication_name).to eq('Medicamento A')
    expect(restored.medication_dosage).to eq('5mg')
    expect(restored.medication_schedule).to eq('08:00')
    expect(restored.medication_notes).to eq('Apos o almoco')
    expect(restored.family_environment_characteristics).to eq('Rotina estruturada')
  end

  it 'keeps the frozen value even after the source discipline is renamed later' do
    plan = create(:individualized_educational_plan)
    review_date = create(:iep_review_date, iep: plan, review_date: Date.current)
    discipline = create(:discipline, description: 'Matemática')
    create(:iep_curricular_planning, iep: plan, iep_review_date: review_date,
                                     discipline: discipline, long_term_goal: 'Meta')

    version = IndividualizedEducationalPlanPublisher.publish!(plan, name: 'Versão 1',
                                                              published_by: create(:user), classroom: create(:classroom))
    discipline.update!(description: 'Matemática I') # renomeada depois da publicação

    restored = IndividualizedEducationalPlanSnapshotRestorer.restore(version.reload.content).plan

    expect(restored.iep_curricular_plannings.first.discipline.description).to eq('Matemática')

    # O id da disciplina está gravado e continua apontando para a linha renomeada: é metadado de
    # restauração, e resolver o nome por ele na leitura devolveria o valor atual, não o congelado.
    snapshot_line = version.content['curricular_plannings'].first
    expect(snapshot_line['discipline_id']).to eq(discipline.id)
    expect(snapshot_line['component_name']).to eq('Matemática')
    expect(Discipline.find(snapshot_line['discipline_id']).description).to eq('Matemática I')
  end
end
