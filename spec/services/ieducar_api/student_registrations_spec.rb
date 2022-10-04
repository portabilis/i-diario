require 'spec_helper'

RSpec.describe IeducarApi::StudentRegistrations, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:unity_id) { 1 }

  subject do
    IeducarApi::StudentRegistrations.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  end

  describe '#fetch' do
    it 'returns student registrations' do

      VCR.use_cassette('student_registrations') do
        result = subject.fetch(aluno_id: [18_625, 18_627])

        expect(result.keys).to include 'matriculas'

        expect(result['matriculas'].size).to eq 9
      end
    end

    it 'necessary to inform aluno_id' do
      expect {
        subject.fetch
      }.to raise_error('É necessário informar o código do aluno')
    end
  end
end
