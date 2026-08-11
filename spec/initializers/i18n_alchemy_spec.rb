require 'rails_helper'

# Datas inexistentes passavam pela checagem de formato da gem e só quebravam ao montar o
# objeto Date, no meio do assign_attributes — antes das validações do model rodarem.
RSpec.describe I18n::Alchemy::DateParser do
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
      expect(event.start_date).to be_blank
    end

    it 'keeps a date that exists' do
      event = SchoolCalendarEvent.new.localized

      event.start_date = '30/06/2026'

      expect(event.start_date).to eq('30/06/2026')
    end
  end
end
