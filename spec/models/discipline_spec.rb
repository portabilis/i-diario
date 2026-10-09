require 'rails_helper'

RSpec.describe Discipline, type: :model do
  describe '#absence_posting_api_code' do
    let(:knowledge_area) { create(:knowledge_area, group_descriptors: true) }

    it 'is the own code for a regular discipline' do
      discipline = create(:discipline, knowledge_area: knowledge_area)

      expect(discipline.absence_posting_api_code).to eq(discipline.api_code)
    end

    context 'when the discipline is the grouper of its knowledge area' do
      let(:grouper) do
        create(:discipline, grouper: true, knowledge_area: knowledge_area, api_code: "grouper:#{knowledge_area.id}")
      end

      it 'is the code of a real discipline of the same area' do
        first_discipline = create(:discipline, knowledge_area: knowledge_area)
        create(:discipline, knowledge_area: knowledge_area)
        create(:discipline)

        expect(grouper.absence_posting_api_code).to eq(first_discipline.api_code)
      end

      it 'is nil when the area has no real discipline' do
        expect(grouper.absence_posting_api_code).to be_nil
      end
    end
  end
end
