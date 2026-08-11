require 'rails_helper'

RSpec.describe DateValidation, type: :controller do
  subject(:controller_class) do
    Class.new do
      include DateValidation

      # Os métodos do concern são privados; o teste os expõe para poder chamá-los direto.
      public :valid_date?, :parse_date
    end.new
  end

  describe '#valid_date?' do
    it 'returns true for an existing date' do
      expect(controller_class.valid_date?('15/06/2026')).to eq(true)
    end

    # Datas com dia ou mês inexistentes são digitadas com frequência nos relatórios.
    it 'returns false for a nonexistent date' do
      expect(controller_class.valid_date?('31/06/2026')).to eq(false)
    end

    it 'returns false for an unparseable date' do
      expect(controller_class.valid_date?('70/82/026_')).to eq(false)
    end

    it 'returns false when the date is blank' do
      expect(controller_class.valid_date?('')).to eq(false)
      expect(controller_class.valid_date?(nil)).to eq(false)
    end
  end

  describe '#parse_date' do
    it 'returns the parsed date for an existing date' do
      expect(controller_class.parse_date('15/06/2026')).to eq(Date.new(2026, 6, 15))
    end

    it 'returns nil for a nonexistent date' do
      expect(controller_class.parse_date('31/06/2026')).to be_nil
    end

    it 'returns nil for an unparseable date' do
      expect(controller_class.parse_date('70/82/026_')).to be_nil
    end

    it 'returns nil when the date is blank' do
      expect(controller_class.parse_date('')).to be_nil
      expect(controller_class.parse_date(nil)).to be_nil
    end
  end
end
