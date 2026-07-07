# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CnpjAlphanumeric do
  # Exemplo oficial da Receita Federal para o CNPJ alfanumerico.
  let(:alphanumeric_cnpj) { '12ABC34501DE35' }
  let(:alphanumeric_masked) { '12.ABC.345/01DE-35' }
  # CNPJ numerico valido (formato antigo, deve continuar aceito).
  let(:numeric_cnpj) { '11222333000181' }
  let(:numeric_masked) { '11.222.333/0001-81' }

  describe '.valid?' do
    it 'accepts a valid alphanumeric CNPJ without mask' do
      expect(described_class.valid?(alphanumeric_cnpj)).to eq(true)
    end

    it 'accepts a valid alphanumeric CNPJ with mask' do
      expect(described_class.valid?(alphanumeric_masked)).to eq(true)
    end

    it 'accepts a valid alphanumeric CNPJ in lowercase' do
      expect(described_class.valid?('12abc34501de35')).to eq(true)
    end

    it 'accepts a valid numeric CNPJ for backward compatibility' do
      expect(described_class.valid?(numeric_cnpj)).to eq(true)
      expect(described_class.valid?(numeric_masked)).to eq(true)
    end

    it 'accepts a CNPJ whose verifier digit is zero' do
      # base 000000000018 => DV 30 (exercita o ramo "resto < 2 => 0" do mod11)
      expect(described_class.valid?('00000000001830')).to eq(true)
    end

    it 'rejects a CNPJ with an incorrect second verifier digit' do
      expect(described_class.valid?('12ABC34501DE34')).to eq(false)
    end

    it 'rejects a CNPJ with an incorrect first verifier digit' do
      expect(described_class.valid?('12ABC34501DE45')).to eq(false)
    end

    it 'rejects a CNPJ with a letter in the verifier digits' do
      expect(described_class.valid?('12ABC34501DEE5')).to eq(false)
    end

    it 'rejects a trivial sequence with all characters equal' do
      expect(described_class.valid?('00000000000000')).to eq(false)
      expect(described_class.valid?('AAAAAAAAAAAA00')).to eq(false)
    end

    it 'rejects values with a length other than 14' do
      expect(described_class.valid?('12ABC34501DE3')).to eq(false)
      expect(described_class.valid?('12ABC34501DE355')).to eq(false)
    end

    it 'rejects nil and empty string' do
      expect(described_class.valid?(nil)).to eq(false)
      expect(described_class.valid?('')).to eq(false)
    end
  end

  describe '.calculate_dv' do
    it 'calculates both verifier digits for the official example' do
      expect(described_class.calculate_dv('12ABC34501DE')).to eq('35')
    end

    it 'calculates the verifier digits for a numeric CNPJ' do
      expect(described_class.calculate_dv('112223330001')).to eq('81')
    end

    it 'returns a zero digit when the mod 11 remainder is below two' do
      expect(described_class.calculate_dv('000000000018')).to eq('30')
    end
  end

  describe '.normalize' do
    it 'removes the mask and upcases the value' do
      expect(described_class.normalize(alphanumeric_masked)).to eq(alphanumeric_cnpj)
    end

    it 'returns an empty string for nil' do
      expect(described_class.normalize(nil)).to eq('')
    end
  end
end
