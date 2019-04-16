require 'rails_helper'

RSpec.describe KnowledgeAreasSynchronizer do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }

  describe '#synchronize!' do
    it 'creates knowledge areas' do
      VCR.use_cassette('all_knowledge_areas') do
        described_class.synchronize_in_batch!(
          synchronization: synchronization,
          worker_batch: worker_batch,
          unities_api_code: Unity.pluck(:api_code)
        )

        expect(KnowledgeArea.count).to eq 14
        first = KnowledgeArea.order(:id).first
        expect(first).to have_attributes(
          'description': '1º Ano - Artes',
          'api_code': '10',
          'sequence': 99_999
        )
      end
    end

    it 'updates knowledge area' do
      VCR.use_cassette('all_knowledge_areas') do
        knowledge_area = create(:knowledge_area,
                                'description': 'ED. FÍSICA',
                                'api_code': '8',
                                'sequence': 2)

        described_class.synchronize_in_batch!(
          synchronization: synchronization,
          worker_batch: worker_batch,
          unities_api_code: Unity.pluck(:api_code)
        )

        expect(KnowledgeArea.count).to eq 14
        expect(knowledge_area.reload).to have_attributes(
          'description': 'EDUCAÇÃO FÍSICA',
          'api_code': '8',
          'sequence': 99_999
        )
      end
    end
  end
end
