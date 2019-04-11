require 'spec_helper'

RSpec.describe IeducarApi::Deficiencies, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:unity_id) { 1 }

  subject do
    IeducarApi::Deficiencies.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  end

  describe '#fetch' do
    it 'returns all deficiencies' do
      VCR.use_cassette('all_deficiencies') do
        result = subject.fetch

        expect(result.keys).to include 'deficiencias'

        expect(result['deficiencias'].size).to eq 16
      end
    end
  end
end
