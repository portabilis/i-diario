require 'rails_helper'

RSpec.describe IeducarApi::PostGeneralAbsences, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:configuration) do
    IeducarApiConfiguration.new(url: 'https://ieducar.example.com', api_security_token: 'shared-secret')
  end
  let(:service) { described_class.new(configuration) }
  let(:params) { { etapa: 1, turma_id: '4502', aluno_id: '1234', faltas: 7 } }

  def http_error(status, body)
    RestClient::ExceptionWithResponse.new(double(code: status, body: body), status)
  end

  describe '#send_post' do
    context 'with local validation (no HTTP call)' do
      it 'requires the step' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:etapa))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar a etapa')
      end

      it 'requires the absences' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:faltas))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar as faltas')
      end

      it 'requires the classroom' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:turma_id))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar a turma')
      end

      it 'requires the student' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:aluno_id))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar o aluno')
      end

      it 'requires the shared token to be configured' do
        configuration.api_security_token = ''
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar o token de segurança do i-Diário')
      end
    end

    context 'on success' do
      it 'posts a flat payload to the api/v2 endpoint authenticated by the shared token' do
        expect(RestClient::Request).to receive(:execute).with(
          method: :post,
          url: 'https://ieducar.example.com/api/v2/falta-geral',
          open_timeout: described_class::OPEN_TIMEOUT,
          read_timeout: described_class::READ_TIMEOUT,
          payload: { turma_id: 4502, aluno_id: 1234, etapa: 1, faltas: 7 }.to_json,
          headers: { token: 'shared-secret', content_type: :json, accept: :json }
        ).and_return(double(body: '{"message":"Faltas gerais salvas com sucesso."}'))

        result = service.send_post(params)

        expect(result).to eq(
          'msgs' => [{ 'msg' => 'Faltas gerais salvas com sucesso.' }],
          'any_error_msg' => false
        )
        expect(IeducarResponseDecorator.new(result).any_error_message?).to eq(false)
      end

      it 'sends zero absences instead of skipping the student' do
        expect(RestClient::Request).to receive(:execute).with(
          hash_including(payload: { turma_id: 4502, aluno_id: 1234, etapa: 1, faltas: 0 }.to_json)
        ).and_return(double(body: '{}'))

        result = service.send_post(params.merge(faltas: 0))

        expect(result['msgs']).to eq([{ 'msg' => 'Faltas postadas com sucesso!' }])
      end
    end

    context 'when the student has no registration in the classroom (404)' do
      it 'returns a warning instead of failing the whole posting' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(404, '{"message":"Matrícula não encontrada para o aluno e turma informados."}')
        )
        expect(Honeybadger).not_to receive(:notify)

        result = service.send_post(params)

        expect(result).to eq(
          'msgs' => [],
          'any_error_msg' => true,
          'error' => { 'message' => 'Matrícula não encontrada para o aluno e turma informados.' }
        )

        response = IeducarResponseDecorator.new(result)

        expect(response.any_error_message?).to eq(true)
        expect(response.full_error_message('Aluno: João;'))
          .to eq('Aluno: João; Matrícula não encontrada para o aluno e turma informados.')
      end
    end

    context 'when the i-Educar rejects the payload (422)' do
      # Corpo real devolvido pelo i-Educar quando a etapa passa do limite aceito pelo endpoint.
      it 'returns a warning with the validation messages' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(422, '{"message":"O campo etapa não pode ser superior a 4.",' \
                          '"errors":{"etapa":["O campo etapa não pode ser superior a 4."]}}')
        )
        expect(Honeybadger).not_to receive(:notify)

        result = service.send_post(params.merge(etapa: 5))

        expect(result['any_error_msg']).to eq(true)
        expect(result['error']).to eq('message' => 'O campo etapa não pode ser superior a 4.')
      end

      it 'falls back to a local message when the body has no text' do
        allow(RestClient::Request).to receive(:execute).and_raise(http_error(422, ''))

        result = service.send_post(params)

        expect(result['error']).to eq('message' => 'O i-Educar recusou os dados enviados.')
      end
    end

    context 'when the shared token diverges between the two systems (401)' do
      it 'raises explaining the integration problem and notifies Honeybadger' do
        allow(RestClient::Request).to receive(:execute).and_raise(http_error(401, '{"message":"Unauthorized"}'))
        expect(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(
          IeducarApi::Base::GenericError,
          'Token de segurança divergente entre o i-Diário e o i-Educar.'
        )
      end
    end

    context 'when the i-Educar fails to save the absences (500)' do
      it 'raises with the remote message so the posting records the error' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(500, '{"message":"Não foi possível salvar as faltas gerais para o aluno e turma informados."}')
        )
        expect(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(
          IeducarApi::Base::GenericError,
          'Não foi possível salvar as faltas gerais para o aluno e turma informados.'
        )
      end
    end

    context 'when the i-Educar is momentarily unavailable' do
      it 'raises NetworkException on a gateway error so the worker retries' do
        allow(RestClient::Request).to receive(:execute).and_raise(http_error(502, ''))

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::NetworkException)
      end

      it 'raises NetworkException on a socket error so the worker retries' do
        allow(RestClient::Request).to receive(:execute).and_raise(SocketError, 'Temporary failure in name resolution')
        allow(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::NetworkException, 'Temporary failure in name resolution')
      end
    end
  end
end
