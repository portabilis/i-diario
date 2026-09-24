require 'rails_helper'

RSpec.describe IeducarApi::PostGeneralAbsences, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:configuration) do
    build(:ieducar_api_configuration, :with_api_security_token, url: 'https://ieducar.example.com')
  end
  let(:token) { configuration.api_security_token }
  let(:service) { described_class.new(configuration) }
  let(:params) { { etapa: 1, turma_id: '4502', aluno_id: '1234', faltas: 7 } }

  # Usa as subclasses concretas do rest-client: a classe pai devolveria "ExceptionWithResponse" em
  # `message`, enquanto produção levanta "500 Internal Server Error" — texto do qual o
  # Ieducar::SendPostWorker depende para classificar o erro.
  def http_error(error_class, status, body)
    error_class.new(double(code: status, body: body), status)
  end

  describe '#initialize' do
    it 'rejects a collaborator that is not an api configuration' do
      expect {
        described_class.new(configuration.to_api)
      }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar a configuração da API do i-Educar')
    end
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

      it 'requires the configured url' do
        configuration.url = ''
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar a url de acesso: url')
      end

      it 'requires the shared token to be configured' do
        configuration.api_security_token = ''
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar o token de segurança do i-Diário')
      end

      it 'rejects a non numeric value instead of coercing it to zero' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.merge(turma_id: 'abc'))
        }.to raise_error(
          IeducarApi::Base::ApiError,
          'O valor informado para a turma não é um número inteiro'
        )
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
          headers: { token: token, content_type: :json, accept: :json }
        ).and_return(double(code: 202, body: '{"message":"Faltas gerais salvas com sucesso."}'))

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
        ).and_return(double(code: 202, body: '{}'))

        result = service.send_post(params.merge(faltas: 0))

        expect(result['msgs']).to eq([{ 'msg' => 'Faltas postadas com sucesso!' }])
      end

      # O endpoint separa "gravou" (202) de "não havia matrícula elegível" (200). O segundo caso é
      # o aluno que deixou de frequentar: desfecho esperado, sobre o qual o professor não tem o
      # que fazer, então não gera aviso na tela — só log.
      it 'does not notify the teacher when there was no eligible registration' do
        allow(RestClient::Request).to receive(:execute).and_return(
          double(code: 200, body: '{"message":"Matrícula não encontrada para o aluno e turma informados."}')
        )
        expect(Honeybadger).not_to receive(:notify)
        expect(Rails.logger).to receive(:warn).with(/matrícula recusada pelo i-Educar/)

        result = service.send_post(params)

        expect(result).to eq('msgs' => [], 'any_error_msg' => false)
        expect(IeducarResponseDecorator.new(result).any_error_message?).to eq(false)
      end

      # Fora do status de gravação, corpo sem mensagem não prova que foi o i-Educar respondendo.
      it 'fails hard on a 200 whose body carries no message' do
        allow(RestClient::Request).to receive(:execute).and_return(double(code: 200, body: '{}'))
        expect(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, /resposta não reconhecida/)
      end

      it 'refuses to treat a non JSON body as a successful post' do
        allow(RestClient::Request).to receive(:execute).and_return(
          double(code: 202, body: '<html><body>502 Bad Gateway</body></html>')
        )
        expect(Honeybadger).to receive(:notify).with(
          instance_of(IeducarApi::Base::GenericError),
          hash_including(context: hash_including(:remote_body))
        )

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, /resposta não reconhecida/)
      end
    end

    context 'when an older i-Educar answers 404 for a registration it does not accept' do
      it 'behaves the same as the 200: log only, no notice' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::NotFound, 404,
            '{"message":"Matrícula não encontrada para o aluno e turma informados."}'
          )
        )
        expect(Honeybadger).not_to receive(:notify)

        result = service.send_post(params)

        expect(result).to eq('msgs' => [], 'any_error_msg' => false)
      end
    end

    context 'when the i-Educar does not publish the endpoint yet (404 without a body)' do
      it 'fails hard instead of reporting a missing registration' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::NotFound, 404, '<html>404 Not Found</html>')
        )
        expect(Honeybadger).to receive(:notify).with(
          instance_of(IeducarApi::Base::GenericError),
          hash_including(context: hash_including(status: 404))
        )

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, /resposta não reconhecida/)
      end
    end

    context "when the classroom's evaluation rule does not allow general absences (422)" do
      # Recusa de negócio que a API legada devolvia como erro conhecido 1008. Continua sendo aviso
      # — derrubar o envio inteiro por causa de uma turma penaliza as demais — e não vai para o
      # Honeybadger: se repete a cada aluno enquanto a divergência de regra existir.
      it 'becomes a warning, without reporting one incident per student' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::UnprocessableEntity, 422,
            '{"message":"A regra da turma 9240 não permite lançamento de faltas geral."}'
          )
        )
        expect(Honeybadger).not_to receive(:notify)

        result = service.send_post(params)

        expect(result).to eq(
          'msgs' => [],
          'any_error_msg' => true,
          'error' => { 'message' => 'A regra da turma 9240 não permite lançamento de faltas geral.' }
        )
      end
    end

    context 'when the i-Educar rejects the payload (422)' do
      # Corpo real do Laravel: `message` genérica e o detalhe útil em `errors`.
      it 'joins every validation message and reports it' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::UnprocessableEntity, 422,
            '{"message":"The given data was invalid.",' \
            '"errors":{"etapa":["O campo etapa não pode ser superior a 4."],' \
            '"aluno_id":["O campo aluno id é obrigatório."]}}'
          )
        )
        expect(Honeybadger).to receive(:notify)

        result = service.send_post(params.merge(etapa: 5))

        expect(result['any_error_msg']).to eq(true)
        expect(result['error']).to eq(
          'message' => 'O campo etapa não pode ser superior a 4. O campo aluno id é obrigatório.'
        )
      end

      it 'falls back to the message when the errors hash is empty' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::UnprocessableEntity, 422, '{"message":"Dados inválidos.","errors":{}}')
        )
        expect(Honeybadger).not_to receive(:notify)

        result = service.send_post(params)

        expect(result['error']).to eq('message' => 'Dados inválidos.')
      end

      it 'fails hard when the body carries no recognizable message' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::UnprocessableEntity, 422, '')
        )
        expect(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, /resposta não reconhecida/)
      end
    end

    context 'when the shared token diverges between the two systems (401)' do
      it 'raises explaining the integration problem and notifies Honeybadger with context' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::Unauthorized, 401, '{"message":"Unauthorized"}')
        )
        expect(Honeybadger).to receive(:notify).with(
          instance_of(RestClient::Unauthorized),
          hash_including(
            context: hash_including(
              endpoint: 'https://ieducar.example.com/api/v2/falta-geral',
              status: 401,
              remote_message: 'Unauthorized'
            )
          )
        )

        expect {
          service.send_post(params)
        }.to raise_error(
          IeducarApi::Base::GenericError,
          'Token de segurança divergente entre o i-Diário e o i-Educar.'
        )
      end
    end

    context 'when the i-Educar fails to save the absences (500)' do
      # O i-Educar passou a repassar a mensagem original do banco entre parênteses. É ela que o
      # Ieducar::SendPostWorker procura em RETRY_ERRORS para refazer a requisição sozinho quando
      # dois envios simultâneos disputam a mesma linha.
      it 'preserves the database message so the worker can retry a duplicate key' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::InternalServerError, 500,
            '{"message":"Não foi possível salvar as faltas gerais para o aluno e turma informados. ' \
            '(SQLSTATE[23505]: Unique violation: 7 ERROR: duplicate key value violates unique ' \
            'constraint \\"falta_geral_pkey\\")"}'
          )
        )
        expect(Honeybadger).to receive(:notify)

        raised = nil

        begin
          service.send_post(params)
        rescue IeducarApi::Base::GenericError => error
          raised = error
        end

        expect(raised.message).to start_with('500 Internal Server Error - ')
        expect(
          Ieducar::SendPostWorker::RETRY_ERRORS.any? { |retry_error| raised.message.include?(retry_error) }
        ).to eq(true)
      end

      it 'falls back to the rest-client text when the body is not JSON' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::InternalServerError, 500, '<html>Server Error</html>')
        )
        expect(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, '500 Internal Server Error')
      end
    end

    context 'when the i-Educar is momentarily unavailable' do
      [
        [RestClient::RequestTimeout, 408, ''],
        [RestClient::TooManyRequests, 429, '{"message":"Too Many Attempts."}'],
        [RestClient::BadGateway, 502, ''],
        [RestClient::ServiceUnavailable, 503, ''],
        [RestClient::GatewayTimeout, 504, '']
      ].each do |error_class, status, body|
        it "raises NetworkException on #{status} so the worker retries, without paging" do
          allow(RestClient::Request).to receive(:execute).and_raise(http_error(error_class, status, body))
          expect(Honeybadger).not_to receive(:notify)

          expect {
            service.send_post(params)
          }.to raise_error(IeducarApi::Base::NetworkException)
        end
      end

      it 'logs what the i-Educar answered when it refuses by rate limit' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::TooManyRequests, 429, '{"message":"Too Many Attempts."}')
        )
        expect(Rails.logger).to receive(:warn).with(/recusa temporária.*status: 429.*Too Many Attempts/)

        expect { service.send_post(params) }.to raise_error(IeducarApi::Base::NetworkException)
      end

      # Este é o caminho mais provável de falha real: uma requisição por aluno num endpoint que
      # ainda recalcula a situação da matrícula.
      [
        RestClient::Exceptions::ReadTimeout,
        RestClient::Exceptions::OpenTimeout,
        RestClient::ServerBrokeConnection,
        RestClient::SSLCertificateNotVerified,
        OpenSSL::SSL::SSLError,
        SocketError
      ].each do |error_class|
        it "raises NetworkException on #{error_class} so the worker retries" do
          allow(RestClient::Request).to receive(:execute).and_raise(error_class, 'falha de transporte')
          expect(Honeybadger).to receive(:notify)

          expect {
            service.send_post(params)
          }.to raise_error(IeducarApi::Base::NetworkException)
        end
      end

      it 'raises NetworkException on a system call error so the worker retries' do
        allow(RestClient::Request).to receive(:execute).and_raise(Errno::ECONNREFUSED)
        expect(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::NetworkException)
      end
    end
  end
end
