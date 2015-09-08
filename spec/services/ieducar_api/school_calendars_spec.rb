require 'spec_helper'

RSpec.describe IeducarApi::SchoolCalendars, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '***REMOVED***' }
  let(:secret_key) { '***REMOVED***' }
  let(:unity_id) { 1 }
  let(:ano) { Date.today.year }

  subject { IeducarApi::SchoolCalendars.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id) }

  describe '#fetch' do
    it 'should return all school calendars' do
      VCR.use_cassette('school_calendars') do
        result = subject.fetch(ano: ano)

        expect(result.keys).to include('escolas')
        expect(result['escolas'].first.keys).to include('escola_id')
        expect(result['escolas'].first.keys).to include('etapas')
      end
    end

    it 'should raise an error when no parameter ano' do
      expect { subject.fetch }.to raise_error('É necessário informar o ano')
    end
  end
end
