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
    it 'accepts a valid alphanumeric CNPJ (sem mascara)' do
      expect(described_class.valid?(alphanumeric_cnpj)).to eq(true)
    end

    it 'accepts a valid alphanumeric CNPJ (com mascara)' do
      expect(described_class.valid?(alphanumeric_masked)).to eq(true)
    end

    it 'accepts a valid alphanumeric CNPJ em minusculas (normaliza para maiusculas)' do
      expect(described_class.valid?('12abc34501de35')).to eq(true)
    end

    it 'accepts a valid numeric CNPJ (compatibilidade)' do
      expect(described_class.valid?(numeric_cnpj)).to eq(true)
      expect(described_class.valid?(numeric_masked)).to eq(true)
    end

    it 'rejects a CNPJ com digito verificador incorreto' do
      expect(described_class.valid?('12ABC34501DE34')).to eq(false)
    end

    it 'rejects a CNPJ com letra no digito verificador' do
      expect(described_class.valid?('12ABC34501DEE5')).to eq(false)
    end

    it 'rejects a sequencia trivial (todos os caracteres iguais)' do
      expect(described_class.valid?('00000000000000')).to eq(false)
      expect(described_class.valid?('AAAAAAAAAAAA00')).to eq(false)
    end

    it 'rejects valores com tamanho diferente de 14' do
      expect(described_class.valid?('12ABC34501DE3')).to eq(false)
      expect(described_class.valid?('12ABC34501DE355')).to eq(false)
    end

    it 'rejects nil e string vazia' do
      expect(described_class.valid?(nil)).to eq(false)
      expect(described_class.valid?('')).to eq(false)
    end
  end

  describe '.calculate_dv' do
    it 'calcula os dois digitos verificadores do exemplo oficial' do
      expect(described_class.calculate_dv('12ABC34501DE')).to eq('35')
    end

    it 'calcula os digitos verificadores de um CNPJ numerico' do
      expect(described_class.calculate_dv('112223330001')).to eq('81')
    end
  end

  describe '.normalize' do
    it 'remove mascara e normaliza para maiusculas' do
      expect(described_class.normalize(alphanumeric_masked)).to eq(alphanumeric_cnpj)
    end

    it 'retorna string vazia para nil' do
      expect(described_class.normalize(nil)).to eq('')
    end
  end
end
