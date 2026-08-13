require 'rails_helper'

RSpec.describe KnowledgeAreasSynchronizer do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }
  let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
  let(:unity) { create(:unity) }
  let(:entity) { Entity.first || create(:entity) }
  let(:year) { Date.current.year }

  let(:synchronizer) do
    described_class.new(
      synchronization: synchronization,
      worker_batch: worker_batch,
      worker_state: worker_state,
      entity_id: entity.id,
      year: year,
      unity_api_code: unity.api_code
    )
  end

  let!(:knowledge_area) { create(:knowledge_area, group_descriptors: true) }

  let!(:grouper_discipline) do
    create(
      :discipline,
      knowledge_area: knowledge_area,
      grouper: true,
      api_code: "grouper:#{knowledge_area.id}"
    )
  end

  let!(:grouper_link) do
    create(:teacher_discipline_classroom, discipline: grouper_discipline, year: Date.current.year)
  end

  def synchronize!(agrupar_descritores:)
    response = {
      'areas' => [
        {
          'id' => knowledge_area.api_code,
          'nome' => knowledge_area.description,
          'ordenamento_ac' => 1,
          'agrupar_descritores' => agrupar_descritores,
          'deleted_at' => nil
        }
      ]
    }

    allow_any_instance_of(IeducarApi::KnowledgeAreas).to receive(:fetch).and_return(response)
    synchronizer.synchronize!
  end

  # Cenário da sincronização simples: a API devolve só a área modificada, nenhuma disciplina —
  # o descarte precisa acontecer aqui, sem depender do DisciplinesSynchronizer
  context 'when group_descriptors is turned off' do
    it 'discards the grouper links' do
      synchronize!(agrupar_descritores: false)

      expect(knowledge_area.reload.group_descriptors).to eq(false)
      expect(grouper_link.reload).to be_discarded
    end

    it 'keeps the grouper discipline' do
      synchronize!(agrupar_descritores: false)

      expect(Discipline.unscoped.where(id: grouper_discipline.id)).to exist
    end
  end

  context 'when group_descriptors stays on' do
    it 'keeps the grouper links' do
      synchronize!(agrupar_descritores: true)

      expect(grouper_link.reload).not_to be_discarded
    end
  end

  context 'when group_descriptors was already off' do
    let!(:knowledge_area) { create(:knowledge_area, group_descriptors: false) }

    it 'does not discard links again (no transition)' do
      discarded_link = create(
        :teacher_discipline_classroom,
        discipline: grouper_discipline,
        year: Date.current.year - 2
      )

      synchronize!(agrupar_descritores: false)

      # Sem transição true->false o descarte não dispara — vínculos de anos fora da
      # sincronização não são alcançados em syncs subsequentes
      expect(discarded_link.reload).not_to be_discarded
    end
  end
end
