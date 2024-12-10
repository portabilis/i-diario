require 'spec_helper'

PRIVATE_ACCESS_KEY = '8IOwGIjiHvbeTklgwo10yVLgwDhhvs'.freeze
PRIVATE_SECRET_KEY = '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC'.freeze

RSpec.describe IeducarApi::Base, type: :service do
  let(:url) { 'https://test.ieducar.com.br' }
  let(:access_key) { PRIVATE_ACCESS_KEY }
  let(:secret_key) { PRIVATE_SECRET_KEY }
  let(:staging_access_key) { PRIVATE_ACCESS_KEY }
  let(:staging_secret_key) { PRIVATE_SECRET_KEY }
  let(:unity_id) { 1 }

  before do
    Rails.application.secrets.staging_access_key = staging_access_key
    Rails.application.secrets.staging_secret_key = staging_secret_key
  end

  context 'ensure obligatory params' do
    it 'requires url' do
      expect {
        IeducarApi::Base.new({})
      }.to raise_error('É necessário informar a url de acesso: url')
    end

    it 'requires access_key' do
      expect {
        IeducarApi::Base.new(url: url)
      }.to raise_error('É necessário informar a chave de acesso: access_key')
    end

    it 'requires secret_key' do
      expect {
        IeducarApi::Base.new(url: url, access_key: access_key)
      }.to raise_error('É necessário informar a chave secreta: secret_key')
    end

    it 'requires unity_id' do
      expect {
        IeducarApi::Base.new(url: url, access_key: access_key, secret_key: secret_key)
      }.to raise_error('É necessário informar o id da unidade: unity_id')
    end
  end

  describe '#fetch' do
    subject do
      IeducarApi::Base.new(url: url, access_key: access_key, secret_key: secret_key, unity_id: unity_id)
    end

    let(:path) { 'module/Api/Aluno' }
    let(:resource) { 'todos-alunos' }

    context 'ensure obligatory options' do
      it 'requires path' do
        expect {
          subject.fetch
        }.to raise_error('É necessário informar o caminho de acesso: path')
      end

      it 'requires resource' do
        expect {
          subject.fetch(path: path)
        }.to raise_error('É necessário informar o recurso de acesso: resource')
      end
    end

    context 'all students' do
      it 'returns all students' do

        VCR.use_cassette('all_students') do
          result = subject.fetch(path: path, resource: resource)

          expect(result.keys).to include 'alunos'

          expect(result['alunos'].size).to eq(29_923)
        end
      end
    end

    context 'when on staging environment' do
      before do
        Rails.stub_chain(:env, staging?: true)

        subject.access_key = nil
        subject.secret_key = nil
        VCR.use_cassette('all_students') do
          subject.fetch(path: path, resource: resource)
        end
      end

      it 'has the staging access key assigned' do
        expect(subject.access_key).to eq(staging_access_key)
      end

      it 'has the staging secret key assigned' do
        expect(subject.secret_key).to eq(staging_secret_key)
      end
    end

    context 'when is not in staging environment' do
      before do
        Rails.stub_chain(:env, staging?: false)

        subject.access_key = nil
        subject.secret_key = nil

        VCR.use_cassette('all_students') do
          expect { subject.fetch(path: path, resource: resource) }.to raise_error('Chave de acesso inválida!')
        end
      end

      it 'does not have the staging access key assigned' do
        expect(subject.access_key).to eq(nil)
      end

      it 'does not have the staging secret key assigned' do
        expect(subject.secret_key).to eq(nil)
      end
    end
  end

  context 'with wrong options' do
    let(:path) { 'module/Api/Aluno' }
    let(:resource) { 'todos-alunos' }

    context 'invalid keys' do
      it 'returns an error when providing an invalid access_key' do
        subject = IeducarApi::Base.new(
          url: url,
          access_key: 'invalid',
          secret_key: secret_key,
          unity_id: unity_id
        )

        VCR.use_cassette('invalid_access_key') do
          expect {
            subject.fetch(path: path, resource: resource)
          }.to raise_error('Chave de acesso inválida!')
        end
      end
    end

    it 'returns an error when providing an invalid url' do
      subject = IeducarApi::Base.new(
        url: 'https://botucat.ieduca.com.br',
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )

      VCR.use_cassette('wrong_url') do
        expect {
          subject.fetch(path: path, resource: resource)
        }.to raise_error('URL do i-Educar informada não é válida.')
      end
    end

    it 'returns an error when providing an invalid client url' do
      subject = IeducarApi::Base.new(
        url: 'https://botucat.ieducar.com.br',
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )

      VCR.use_cassette('wrong_client_url') do
        expect {
          subject.fetch(path: path, resource: resource)
        }.to raise_error(IeducarApi::Base::ApiError)
      end
    end

    it 'returns an error when providing an invalid resource' do

      subject = IeducarApi::Base.new(
        url: url,
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )

      VCR.use_cassette('wrong_resource') do
        expect {
          subject.fetch(path: path, resource: 'errado')
        }.to raise_error("Operação 'get' não implementada para o recurso 'errado'")
      end
    end
  end

  describe '#send_post' do
    subject do
      IeducarApi::Base.new(
        url: url,
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )
    end

    let(:path) { 'module/Api/Diario' }
    let(:resource) { 'faltas-geral' }

    context 'ensure obligatory options' do
      it 'requires path' do
        expect {
          subject.send_post
        }.to raise_error('É necessário informar o caminho de acesso: path')
      end

      it 'requires resource' do
        expect {
          subject.send_post(path: path)
        }.to raise_error('É necessário informar o recurso de acesso: resource')
      end
    end

    context 'assign staging secret keys when not in production' do
      before do
        Rails.stub_chain(:env, production?: false)
        subject.stub(:request).and_return(true)
        subject.access_key = nil
        subject.secret_key = nil

        VCR.use_cassette('post_absence_resource') do
          subject.send_post(
            path: path,
            resource: resource,
            etapa: 1,
            faltas: 1
          )
        end
      end

      it 'access_key is the staging access_key' do
        expect(subject.access_key).to eq(staging_access_key)
      end

      it 'secret_key is the staging secret_key' do
        expect(subject.secret_key).to eq(staging_secret_key)
      end
    end

    context 'do not assign staging secret keys when in production' do
      before do
        Rails.stub_chain(:env, production?: true)
        subject.access_key = nil
        subject.secret_key = nil

        VCR.use_cassette('post_invalid_access_key') do
          expect {
            subject.send_post(
              path: path,
              resource: resource,
              etapa: 1,
              faltas: 1
            )
          }.to raise_error('Chave de acesso inválida!')
        end
      end

      it 'access_key is the nil' do
        expect(subject.access_key).to eq(nil)
      end

      it 'secret_key is the nil' do
        expect(subject.secret_key).to eq(nil)
      end
    end
  end

  context 'with wrong options' do
    let(:path) { 'module/Api/Diario' }
    let(:resource) { 'faltas-geral' }
    let(:params) { { path: path, resource: resource, etapa: 1, faltas: 1 } }

    before do
      Rails.stub_chain(:env, production?: true)
    end

    context 'invalid keys' do
      it 'returns an error when providing an invalid access_key' do
        subject = IeducarApi::Base.new(
          url: url,
          access_key: 'invalid',
          secret_key: secret_key,
          unity_id: unity_id
        )

        VCR.use_cassette('post_invalid_access_key') do
          expect {
            subject.send_post(params)
          }.to raise_error('Chave de acesso inválida!')
        end
      end
    end

    it 'returns an error when providing an invalid url' do
      subject = IeducarApi::Base.new(
        url: 'https://botucat.ieduca.com.br',
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )

      expect {
        subject.send_post(params)
      }.to raise_error(IeducarApi::Base::ApiError)
    end

    it 'returns an error when providing an invalid client url' do
      subject = IeducarApi::Base.new(
        url: 'https://botucat.ieducar.com.br',
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )

      VCR.use_cassette('post_wrong_client_url') do
        expect {
          subject.send_post(params)
        }.to raise_error(IeducarApi::Base::ApiError)
      end
    end

    it 'returns an error when providing an invalid resource' do
      subject = IeducarApi::Base.new(
        url: url,
        access_key: access_key,
        secret_key: secret_key,
        unity_id: unity_id
      )

      VCR.use_cassette('post_wrong_resource') do
        expect {
          subject.send_post(path: path, resource: 'errado')
        }.to raise_error(IeducarApi::Base::ApiError)
      end
    end
  end
end
