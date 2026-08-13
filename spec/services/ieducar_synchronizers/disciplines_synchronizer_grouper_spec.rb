require 'rails_helper'

RSpec.describe DisciplinesSynchronizer do
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

  let(:knowledge_area) { create(:knowledge_area, group_descriptors: group_descriptors) }
  let(:discipline) { create(:discipline, knowledge_area: knowledge_area) }

  let!(:grouper_discipline) do
    create(
      :discipline,
      knowledge_area: knowledge_area,
      grouper: true,
      api_code: "grouper:#{knowledge_area.id}"
    )
  end

  # `year` explícito porque em um dos contexts o parâmetro do synchronizer é uma string
  # com vários anos, e não serviria para montar o vínculo
  let!(:grouper_link) do
    create(:teacher_discipline_classroom, discipline: grouper_discipline, year: Date.current.year)
  end

  def synchronize!
    response = {
      'disciplinas' => [
        {
          'id' => discipline.api_code,
          'nome' => discipline.description,
          'ordenamento' => 1,
          'area_conhecimento_id' => knowledge_area.api_code
        }
      ]
    }

    allow_any_instance_of(IeducarApi::Disciplines).to receive(:fetch).and_return(response)
    synchronizer.synchronize!
  end

  context 'when the knowledge area no longer groups descriptors' do
    let(:group_descriptors) { false }

    it 'discards the grouper links' do
      synchronize!

      expect(grouper_link.reload).to be_discarded
    end

    it 'keeps the grouper discipline so historical records stay intact' do
      synchronize!

      expect(Discipline.unscoped.where(id: grouper_discipline.id)).to exist
    end

    # Anos encerrados guardam planos de aula, conteúdos e frequências lançados sob a agrupadora
    it 'does not discard links from years outside the synchronization' do
      closed_year_link = create(
        :teacher_discipline_classroom,
        discipline: grouper_discipline,
        year: Date.current.year - 2
      )

      synchronize!

      expect(closed_year_link.reload).not_to be_discarded
    end

    # O SynchronizerBuilder manda todos os anos numa string única para synchronizers
    # `by_year: false`, e não um worker por ano
    context 'when the synchronization covers more than one year' do
      let(:year) { "#{Date.current.year},#{Date.current.year - 1}" }

      let!(:previous_year_link) do
        create(
          :teacher_discipline_classroom,
          discipline: grouper_discipline,
          year: Date.current.year - 1
        )
      end

      it 'discards the links of every synchronized year' do
        synchronize!

        expect(grouper_link.reload).to be_discarded
        expect(previous_year_link.reload).to be_discarded
      end
    end

    it 'does not discard links of other knowledge areas' do
      other_link = create(:teacher_discipline_classroom, year: Date.current.year)

      synchronize!

      expect(other_link.reload).not_to be_discarded
    end
  end

  context 'when the knowledge area groups descriptors' do
    let(:group_descriptors) { true }

    it 'keeps the grouper links' do
      synchronize!

      expect(grouper_link.reload).not_to be_discarded
    end

    it 'creates the grouper discipline when it does not exist yet' do
      other_knowledge_area = create(:knowledge_area, group_descriptors: true)
      other_discipline = create(:discipline, knowledge_area: other_knowledge_area)

      response = {
        'disciplinas' => [
          {
            'id' => other_discipline.api_code,
            'nome' => other_discipline.description,
            'ordenamento' => 1,
            'area_conhecimento_id' => other_knowledge_area.api_code
          }
        ]
      }

      allow_any_instance_of(IeducarApi::Disciplines).to receive(:fetch).and_return(response)
      synchronizer.synchronize!

      expect(
        Discipline.unscoped.find_by(
          knowledge_area_id: other_knowledge_area.id,
          grouper: true,
          api_code: "grouper:#{other_knowledge_area.id}"
        )
      ).to be_present
    end
  end
end
