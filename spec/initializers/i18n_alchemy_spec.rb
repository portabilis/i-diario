require 'rails_helper'

# Datas inexistentes passavam pela checagem de formato da gem e só quebravam ao montar o
# objeto Date, na atribuição do atributo — antes das validações do model rodarem.
#
# O tipo é declarado porque o RSpec não infere tipo para esta pasta, e sem ele o
# DatabaseCleaner não roda: os registros criados no before(:each) global ficariam no banco.
RSpec.describe I18n::Alchemy::DateParser, type: :model do
  describe '.parse' do
    it 'parses a date that exists' do
      expect(described_class.parse('30/06/2026')).to eq('2026-06-30')
    end

    it 'returns a blank value for a date that does not exist' do
      expect(described_class.parse('31/06/2026')).to eq('')
    end

    it 'keeps an unrecognized value untouched' do
      expect(described_class.parse('70/82/026_')).to eq('70/82/026_')
    end
  end

  describe 'assigning to a localized model' do
    it 'leaves the attribute blank instead of raising Date::Error' do
      event = SchoolCalendarEvent.new.localized

      expect { event.start_date = '31/06/2026' }.not_to raise_error
      expect(event.start_date).to be_nil
    end

    it 'keeps a date that exists' do
      event = SchoolCalendarEvent.new.localized

      event.start_date = '30/06/2026'

      expect(event.start_date).to eq('30/06/2026')
    end

    # A data inexistente precisa chegar como erro do campo, e não derrubar a requisição.
    it 'reports the field as invalid' do
      event = SchoolCalendarEvent.new.localized
      event.start_date = '31/06/2026'

      event.valid?

      expect(event.errors[:start_date]).to include(I18n.t('errors.messages.invalid_date'))
    end
  end

  # Um formato de data mal configurado produziria argumentos inválidos por outro motivo:
  # nesse caso a exceção precisa continuar subindo, para não silenciar o erro real.
  describe 'when the parsed date is incomplete' do
    it 'lets the error surface' do
      expect { described_class.send(:build_object, mday: 15, mon: 6) }.to raise_error(ArgumentError)
    end
  end
end
