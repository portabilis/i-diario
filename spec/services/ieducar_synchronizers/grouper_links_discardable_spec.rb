require 'rails_helper'

RSpec.describe GrouperLinksDiscardable do
  # Includer mínimo: o módulo depende apenas do reader `year`
  let(:includer_class) do
    Struct.new(:year) do
      include GrouperLinksDiscardable
    end
  end

  def synchronized_years_for(year)
    includer_class.new(year).send(:synchronized_years)
  end

  describe '#synchronized_years' do
    it 'parses a single-year string' do
      expect(synchronized_years_for('2026')).to eq([2026])
    end

    it 'parses a multi-year string' do
      expect(synchronized_years_for('2026,2025')).to eq([2026, 2025])
    end

    it 'parses an integer' do
      expect(synchronized_years_for(2026)).to eq([2026])
    end

    it 'returns empty for nil' do
      expect(synchronized_years_for(nil)).to eq([])
    end

    it 'returns empty for a blank string' do
      expect(synchronized_years_for('')).to eq([])
    end

    it 'returns empty for a non-numeric string' do
      expect(synchronized_years_for('abc')).to eq([])
    end
  end

  describe '#discard_grouper_links' do
    let(:knowledge_area) { create(:knowledge_area, group_descriptors: false) }

    let!(:grouper_discipline) do
      create(:discipline, knowledge_area: knowledge_area, grouper: true)
    end

    let!(:grouper_link) do
      create(:teacher_discipline_classroom, discipline: grouper_discipline, year: Date.current.year)
    end

    context 'when the year param is empty' do
      it 'discards nothing and logs an error' do
        expect(Rails.logger).to receive(:error).with(/year vazio ou inválido/)

        includer_class.new('').send(:discard_grouper_links, knowledge_area)

        expect(grouper_link.reload).not_to be_discarded
      end
    end

    context 'when the area has duplicated grouper disciplines' do
      # Agrupadoras legadas têm api_code em formato antigo — o descarte não pode depender do formato
      it 'discards the links of every grouper discipline of the area' do
        legacy_grouper = create(
          :discipline,
          knowledge_area: knowledge_area,
          grouper: true,
          api_code: '00'
        )
        legacy_link = create(:teacher_discipline_classroom, discipline: legacy_grouper, year: Date.current.year)

        includer_class.new(Date.current.year.to_s).send(:discard_grouper_links, knowledge_area)

        expect(grouper_link.reload).to be_discarded
        expect(legacy_link.reload).to be_discarded
      end
    end
  end
end
