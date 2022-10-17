require 'spec_helper'

RSpec.describe IeducarApi::PostAbsences, type: :service do
  let(:url) { 'https://test.ieducar.com.br' }
  let(:access_key) { '2Me9freQ6gpneyCOlWRcVSx2huwa3X' }
  let(:secret_key) { '7AWURgchB84ZeY7q8voyIuJeATOsny' }
  let(:unity_id) { 1 }
  let(:resource) { 'faltas-geral' }
  let(:etapa) { 1 }
  let(:faltas) { '1' }

  subject do
    IeducarApi::PostAbsences.new(
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
      VCR.use_cassette('post_absences') do
        result = subject.send_post(
          etapa: etapa,
          faltas: faltas,
          resource: resource
        )

        expect(result.keys).to include 'msgs'
      end
    end

    it 'necessary to inform resource' do
      expect {
        subject.send_post(
          unity_id: 1,
          faltas: faltas,
          etapa: etapa
        )
      }.to raise_error('É necessário informar o recurso')
    end

    it 'necessary to inform absences' do
      expect {
        subject.send_post(
          unity_id: 1,
          resource: resource,
          etapa: etapa
        )
      }.to raise_error('É necessário informar as faltas')
    end

    it 'necessary to inform etapa' do
      expect {
        subject.send_post(
          unity_id: 1,
          faltas: faltas,
          resource: resource
        )
      }.to raise_error('É necessário informar a etapa')
    end
  end
end
