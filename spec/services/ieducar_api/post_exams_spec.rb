require 'rails_helper'

RSpec.describe IeducarApi::PostExams, type: :service do
  let(:url) { 'https://test.ieducar.com.br' }
  let(:access_key) { '2Me9freQ6gpneyCOlWRcVSx2huwa3X' }
  let(:secret_key) { '7AWURgchB84ZeY7q8voyIuJeATOsny' }
  let(:unity_id) { 1 }
  let(:resource) { 'notas' }
  let(:etapa) { 1 }
  let(:notas) { '1' }

  subject do
    IeducarApi::PostExams.new(
      url: url,
      access_key: access_key,
      secret_key: secret_key,
      unity_id: unity_id
    )
  end

  describe '#send_post' do
    it 'returns message' do
      allow(Rails.application.secrets).to receive(:staging_access_key).and_return(access_key)
      allow(Rails.application.secrets).to receive(:staging_secret_key).and_return(secret_key)
      # A URI da cassette leva o payload na query string e não casa com a do POST do serviço, que
      # manda o payload no corpo: pelo matcher padrão o VCR não acha a interação e sai para a rede.
      VCR.use_cassette('post_exams', match_requests_on: %i[method path]) do
        result = subject.send_post(
          etapa: etapa,
          notas: notas,
          resource: resource
        )

        expect(result.keys).to include 'msgs'
        expect(result['any_error_msg']).to be false
      end
    end

    it 'necessary to inform scores' do
      expect {
        subject.send_post(
          unity_id: 1,
          etapa: etapa,
          resource: resource
        )
      }.to raise_error('É necessário informar as notas')
    end

    it 'necessary to inform etapa' do
      expect {
        subject.send_post(
          unity_id: 1,
          notas: notas,
          resource: resource
        )
      }.to raise_error('É necessário informar a etapa')
    end

    it 'necessary to inform resource' do
      expect {
        subject.send_post(
          unity_id: 1,
          notas: notas,
          etapa: etapa
        )
      }.to raise_error('É necessário informar o recurso')
    end
  end
end
