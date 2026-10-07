require 'rails_helper'

# O tratamento de status, retry e autenticação é o de IeducarApi::V2Base, coberto em
# post_general_absences_spec.rb; aqui ficam o contrato do callback e o status de sucesso dele.
RSpec.describe IeducarApi::PostComponentBatchCallback, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:configuration) do
    build(:ieducar_api_configuration, :with_api_security_token, url: 'https://ieducar.example.com')
  end
  let(:token) { configuration.api_security_token }
  let(:service) { described_class.new(configuration) }

  def http_error(error_class, status, body)
    error_class.new(double(code: status, body: body), status)
  end

  describe '#send_post' do
    it 'requires the operation' do
      expect(RestClient::Request).not_to receive(:execute)

      expect {
        service.send_post(success: true, deleted: 3)
      }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar a operação')
    end

    it 'posts the result of a successful deletion authenticated by the shared token' do
      expect(RestClient::Request).to receive(:execute).with(
        method: :post,
        url: 'https://ieducar.example.com/api/v2/component-batch-callback',
        open_timeout: described_class::OPEN_TIMEOUT,
        read_timeout: described_class::READ_TIMEOUT,
        payload: { operation_id: 42, success: true, deleted: 3 }.to_json,
        headers: { token: token, content_type: :json, accept: :json }
      ).and_return(double(code: 200, body: '{"message":"Callback processado com sucesso."}'))

      result = service.send_post(operation_id: 42, success: true, deleted: 3)

      expect(result).to eq('msgs' => [{ 'msg' => 'Callback processado com sucesso.' }], 'any_error_msg' => false)
    end

    it 'posts the error of a failed deletion' do
      expect(RestClient::Request).to receive(:execute).with(
        hash_including(payload: { operation_id: 42, success: false, deleted: 0, error: 'falha' }.to_json)
      ).and_return(double(code: 200, body: '{"message":"Callback processado com sucesso."}'))

      service.send_post(operation_id: 42, success: false, deleted: 0, error: 'falha')
    end

    # O i-Educar não reprocessa a operação já encerrada e responde 200 informando o status atual.
    it 'accepts the 200 of an operation that is no longer running' do
      allow(RestClient::Request).to receive(:execute).and_return(
        double(code: 200, body: '{"message":"Operação não está em execução. Status atual: Concluída"}')
      )

      expect(service.send_post(operation_id: 42, success: true, deleted: 3)).to eq(
        'msgs' => [{ 'msg' => 'Operação não está em execução. Status atual: Concluída' }],
        'any_error_msg' => false
      )
    end

    it 'fails hard on a 201, which is not the status of this endpoint' do
      allow(RestClient::Request).to receive(:execute).and_return(double(code: 201, body: '{"message":"ok"}'))
      allow(Honeybadger).to receive(:notify)

      expect {
        service.send_post(operation_id: 42, success: true)
      }.to raise_error(IeducarApi::Base::GenericError, /resposta não reconhecida/)
    end

    it 'reports an unknown operation refused by the i-Educar' do
      allow(RestClient::Request).to receive(:execute).and_raise(
        http_error(
          RestClient::UnprocessableEntity, 422,
          '{"message":"Operação não encontrada.","errors":{"operation_id":["Operação não encontrada."]}}'
        )
      )
      expect(Honeybadger).to receive(:notify)

      expect(service.send_post(operation_id: 42, success: true)['error']).to eq('message' => 'Operação não encontrada.')
    end
  end
end
