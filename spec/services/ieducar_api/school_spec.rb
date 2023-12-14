require 'spec_helper'

RSpec.describe IeducarApi::Schools, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '2Me9freQ6gpneyCOlWRcVSx2huwa3X' }
  let(:secret_key) { '7AWURgchB84ZeY7q8voyIuJeATOsny' }
  let(:unity_id) { 1 }
  let(:resource) { 'info-escolas' }
  let(:path) { 'module/Api/Escola' }

  subject {
    IeducarApi::Schools.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  }

  describe '#fetch_all' do
    it 'should return all schools' do
      VCR.use_cassette('schools') do
        result = subject.fetch(escola: unity_id, resource: resource, path: path)

        expect(result.keys).to include('escolas')
        expect(result['escolas'].size).to eq(23)
      end
    end
  end
end
