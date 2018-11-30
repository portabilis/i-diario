require 'spec_helper'

RSpec.describe IeducarApi::StudentsInFinalRecovery, type: :service do
  let(:url) { 'http://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:entity_id) { 1 }

  subject do
    IeducarApi::StudentsInFinalRecovery.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: entity_id
    )
  end

  describe '#fetch' do
    it 'returns students in final recovery' do
      VCR.use_cassette('students_in_final_recovery') do
        result = subject.fetch(
          classroom_api_code: 4244,
          discipline_api_code: 3187
        )

        expect(result.keys).to include('alunos')

        expect(result['alunos'].first['id']).to_not be_blank
        expect(result['alunos'].first['nota_exame']).to_not be_blank
      end
    end

    it 'necessary to inform classroom_api_code' do
      expect {
        subject.fetch(discipline_api_code: 3187)
      }.to raise_error('É necessário informar a turma: classroom_api_code')
    end

    it 'necessary to inform discipline_api_code' do
      expect {
        subject.fetch(classroom_api_code: 4244)
      }.to raise_error('É necessário informar a disciplina: discipline_api_code')
    end
  end
end
