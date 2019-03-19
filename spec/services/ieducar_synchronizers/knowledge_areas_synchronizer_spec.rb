require 'rails_helper'

RSpec.describe KnowledgeAreasSynchronizer do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }

  describe '#synchronize!' do
    it 'creates knowledge areas' do
      VCR.use_cassette('all_knowledge_areas') do
        described_class.synchronize_in_batch!(synchronization, worker_batch)

        expect(KnowledgeArea.count).to eq 14
        first = KnowledgeArea.order(:id).first
        expect(first).to have_attributes(
          'description': 'Artes e Música',
          'api_code': '7',
          'sequence': 3
        )
      end
    end

    it 'updates knowledge area' do
      VCR.use_cassette('all_knowledge_areas') do
        knowledge_area = create(:knowledge_area,
                                'description': 'ARTES',
                                'api_code': '8',
                                'sequence': 2)

        described_class.synchronize_in_batch!(synchronization, worker_batch)

        expect(KnowledgeArea.count).to eq 14
        expect(knowledge_area.reload).to have_attributes(
          'description': 'Linguagem Oral e Escrita',
          'api_code': '8',
          'sequence': 4
        )
      end
    end
  end
end
