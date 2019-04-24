require 'rails_helper'

RSpec.describe DisciplinesSynchronizer do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }

  before do
    VCR.use_cassette('all_knowledge_areas') do
      KnowledgeAreasSynchronizer.synchronize_in_batch!(synchronization, worker_batch)
    end
  end

  describe '#synchronize!' do
    it 'creates knowledge areas' do
      VCR.use_cassette('all_disciplines') do
        described_class.synchronize_in_batch!(synchronization, worker_batch)

        expect(Discipline.count).to eq 278
        first = Discipline.order(:id).first
        expect(first).to have_attributes(
          'description': 'Adota hábitos de autocuidado relacionado à higiene, alimentação, conforto, segurança, proteção e cuidado com a aparência.',
          'api_code': '215',
          'knowledge_area_id': KnowledgeArea.find_by(api_code: 5).id,
          'sequence': 9
        )
      end
    end

    it 'updates knowledge area' do
      VCR.use_cassette('all_disciplines') do
        discipline = create(:discipline,
                            'description': 'Adota.',
                            'api_code': '215',
                            'knowledge_area_id': KnowledgeArea.last.id,
                            'sequence': 10)

        described_class.synchronize_in_batch!(synchronization, worker_batch)

        expect(Discipline.count).to eq 278
        expect(discipline.reload).to have_attributes(
          'description': 'Adota hábitos de autocuidado relacionado à higiene, alimentação, conforto, segurança, proteção e cuidado com a aparência.',
          'api_code': '215',
          'knowledge_area_id': KnowledgeArea.find_by(api_code: 5).id,
          'sequence': 9
        )
      end
    end
  end
end
