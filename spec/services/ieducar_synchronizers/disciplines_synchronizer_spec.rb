require 'rails_helper'

RSpec.describe DisciplinesSynchronizer do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }
  let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }

  before do
    VCR.use_cassette('all_knowledge_areas') do
      KnowledgeAreasSynchronizer.synchronize!(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state_id: worker_state.id,
        year: Date.current.year,
        unity_api_code: Unity.first.api_code,
        entity_id: Entity.first.id
      )
    end
  end

  describe '#synchronize!' do

    it 'creates knowledge areas' do
      VCR.use_cassette('all_disciplines') do
        described_class.synchronize!(
          synchronization: synchronization,
          worker_batch: worker_batch,
          worker_state_id: worker_state.id,
          year: Date.current.year,
          unity_api_code: Unity.first.api_code,
          entity_id: Entity.first.id
        )
    
        expect(Discipline.count).to eq 332
        first = Discipline.order(:id).first
        expect(first).to have_attributes(
          'description': 'Abre e fecha zíper e tira os próprios sapatos.',
          'api_code': '64',
          'knowledge_area_id': KnowledgeArea.find_by(api_code: 4).id,
          'sequence': 99_999
        )
      end
    end
    
    it 'updates knowledge area' do
      VCR.use_cassette('all_disciplines') do
        discipline = create(:discipline,
                            'description': 'Adota.',
                            'api_code': '64',
                            'knowledge_area_id': KnowledgeArea.last.id,
                            'sequence': 10)
    
        described_class.synchronize!(
          synchronization: synchronization,
          worker_batch: worker_batch,
          worker_state_id: worker_state.id,
          year: Date.current.year,
          unity_api_code: Unity.first.api_code,
          entity_id: Entity.first.id
        )
    
        expect(Discipline.count).to eq 332
        expect(discipline.reload).to have_attributes(
          'description': 'Abre e fecha zíper e tira os próprios sapatos.',
          'api_code': '64',
          'knowledge_area_id': KnowledgeArea.find_by(api_code: 4).id,
          'sequence': 99_999
        )
      end
    end
  end
end
