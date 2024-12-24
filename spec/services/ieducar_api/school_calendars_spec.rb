require 'spec_helper'

RSpec.describe IeducarApi::SchoolCalendars, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:unity_id) { 1 }
  let(:year) { Time.zone.today.year }

  subject {
    IeducarApi::SchoolCalendars.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  }

  describe '#fetch' do
    it 'should return all school calendars' do

      VCR.use_cassette('school_calendars') do
        result = subject.fetch(ano: year, escola: unity_id)

        expect(result.keys).to include('escolas')
        expect(result['escolas'].first.keys).to include('escola_id')
        expect(result['escolas'].first.keys).to include('ano')
        expect(result['escolas'].first.keys).to include('etapas')
      end
    end
  end
end
