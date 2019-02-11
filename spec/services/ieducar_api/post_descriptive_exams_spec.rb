require 'spec_helper'

RSpec.describe IeducarApi::PostDescriptiveExams, type: :service do
  let(:url) { 'https://test.ieducar.com.br' }
  let(:access_key) { '8IOwGIjiHvbeTklgwo10yVLgwDhhvs' }
  let(:secret_key) { '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC' }
  let(:unity_id) { 1 }
  let(:resource) { 'pareceres-anual-geral' }
  let(:etapa) { 1 }
  let(:pareceres) { '1' }

  subject do
    IeducarApi::PostDescriptiveExams.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  end

  describe '#send_post' do
    it 'returns message' do
      VCR.use_cassette('post_descriptive_exams') do
        result = subject.send_post(
          etapa: etapa,
          pareceres: pareceres,
          resource: resource
        )

        expect(result.keys).to include 'msgs'
      end
    end

    it 'necessary to inform classrooms' do
      expect {
        subject.send_post(
          unity_id: 1
        )
      }.to raise_error('É necessário informar os pareceres')
    end

    it 'necessary to inform resource' do
      expect {
        subject.send_post(
          unity_id: 1,
          pareceres: pareceres
        )
      }.to raise_error('É necessário informar o recurso')
    end
  end
end
