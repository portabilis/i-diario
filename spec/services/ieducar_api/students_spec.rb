require 'spec_helper'

RSpec.describe IeducarApi::Students, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:unity_id) { 1 }

  subject do
    IeducarApi::Students.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  end

  describe '#fetch' do
    it 'returns all students' do
      VCR.use_cassette('all_students') do
        result = subject.fetch(escola: unity_id)

        expect(result.keys).to include 'alunos'

        expect(result['alunos'].size).to eq 2092
      end
    end
  end
end
