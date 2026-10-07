require 'rails_helper'

# O tratamento de status, retry e autenticação é o de IeducarApi::V2Base, coberto em
# post_general_absences_spec.rb; aqui ficam o contrato do endpoint de notas e as recusas dele.
RSpec.describe IeducarApi::PostScores, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:configuration) do
    build(:ieducar_api_configuration, :with_api_security_token, url: 'https://ieducar.example.com')
  end
  let(:token) { configuration.api_security_token }
  let(:service) { described_class.new(configuration) }
  let(:params) { { etapa: 2, turma_id: '4502', aluno_id: '1234', componente_id: '17', nota: '7.5' } }

  def http_error(error_class, status, body)
    error_class.new(double(code: status, body: body), status)
  end

  def expect_payload(payload)
    expect(RestClient::Request).to receive(:execute).with(
      hash_including(payload: payload.to_json)
    ).and_return(double(code: 201, body: '{"message":"Nota salva com sucesso."}'))
  end

  describe '#send_post' do
    context 'with local validation (no HTTP call)' do
      it 'requires the discipline' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:componente_id))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar o componente curricular')
      end

      it 'requires the score' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:nota))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar a nota')
      end

      it 'rejects a non numeric score instead of sending zero' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.merge(nota: 'abc'))
        }.to raise_error(IeducarApi::Base::ApiError, 'O valor informado para a nota não é um número')
      end

      it 'rejects a step that is neither a number nor the final recovery' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.merge(etapa: 'rc'))
        }.to raise_error(IeducarApi::Base::ApiError, 'O valor informado para a etapa não é um número inteiro')
      end
    end

    context 'on success' do
      it 'posts a flat payload to the scores endpoint authenticated by the shared token' do
        expect(RestClient::Request).to receive(:execute).with(
          method: :post,
          url: 'https://ieducar.example.com/api/v2/notas',
          open_timeout: described_class::OPEN_TIMEOUT,
          read_timeout: described_class::READ_TIMEOUT,
          payload: { turma_id: 4502, aluno_id: 1234, componente_id: 17, etapa: 2, nota: 7.5 }.to_json,
          headers: { token: token, content_type: :json, accept: :json }
        ).and_return(double(code: 201, body: '{"message":"Nota salva com sucesso."}'))

        result = service.send_post(params)

        expect(result).to eq(
          'msgs' => [{ 'msg' => 'Nota salva com sucesso.' }],
          'any_error_msg' => false
        )
      end

      it 'sends the step recovery together with the score' do
        expect_payload(turma_id: 4502, aluno_id: 1234, componente_id: 17, etapa: 2, nota: 7.5, recuperacao: 8.25)

        service.send_post(params.merge(recuperacao: BigDecimal('8.25')))
      end

      it 'sends the final recovery on the Rc step' do
        expect_payload(turma_id: 4502, aluno_id: 1234, componente_id: 17, etapa: 'Rc', nota: 6.0)

        service.send_post(params.merge(etapa: 'Rc', nota: 6))
      end

      # A nota conceitual é decimal no banco e chega como string depois do JSON do Sidekiq.
      it 'sends a decimal score as a JSON number' do
        expect_payload(turma_id: 4502, aluno_id: 1234, componente_id: 17, etapa: 2, nota: 3.0)

        service.send_post(params.merge(nota: BigDecimal('3.0')))
      end

      it 'sends zero instead of skipping the score' do
        expect_payload(turma_id: 4502, aluno_id: 1234, componente_id: 17, etapa: 2, nota: 0.0)

        service.send_post(params.merge(nota: 0))
      end

      it 'falls back to the default message when the body has none' do
        allow(RestClient::Request).to receive(:execute).and_return(double(code: 201, body: '{}'))

        expect(service.send_post(params)['msgs']).to eq([{ 'msg' => 'Notas postadas com sucesso!' }])
      end
    end

    context 'when the i-Educar finds no eligible registration (422 on aluno_id)' do
      it 'logs it with the discipline and the score, without a notice for the teacher' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::UnprocessableEntity, 422,
            '{"message":"Matrícula não encontrada para o aluno e turma informados.",' \
            '"errors":{"aluno_id":["Matrícula não encontrada para o aluno e turma informados."]}}'
          )
        )
        expect(Honeybadger).not_to receive(:notify)
        expect(Rails.logger).to receive(:warn).with(
          /\[notas\] matrícula recusada .* etapa: 2, componente: 17, nota: 7.5, status: 422/
        )

        expect(service.send_post(params)).to eq('msgs' => [], 'any_error_msg' => false)
      end
    end

    # Recusas de regra: se repetem a cada aluno enquanto a divergência existir, então viram aviso
    # no envio sem abrir um incidente por aluno.
    [
      'A nota 12 está acima da configurada para nota máxima geral que é 10.',
      'A nota -1 está abaixo da configurada para nota mínima geral que é 0.',
      'A nota 12 está acima da configurada para nota máxima para exame que é 10.',
      'Nota somente pode ser lançada após lançar notas nas etapas: 1º Bimestre',
      'Componente curricular de código 17 não existe para a turma 4502.'
    ].each do |message|
      it "becomes a warning when the i-Educar answers: #{message}" do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::UnprocessableEntity, 422, { message: message }.to_json)
        )
        expect(Honeybadger).not_to receive(:notify)

        expect(service.send_post(params)).to eq(
          'msgs' => [],
          'any_error_msg' => true,
          'error' => { 'message' => message }
        )
      end
    end

    context 'when the i-Educar rejects the payload (422 on another field)' do
      it 'reports it, because the payload broke the contract' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::UnprocessableEntity, 422,
            '{"message":"The given data was invalid.","errors":{"etapa":["O campo etapa selecionado é inválido."]}}'
          )
        )
        expect(Honeybadger).to receive(:notify)

        result = service.send_post(params.merge(etapa: 5))

        expect(result['error']).to eq('message' => 'O campo etapa selecionado é inválido.')
      end
    end

    context 'when the i-Educar does not publish the endpoint yet (404)' do
      it 'fails hard' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::NotFound, 404, '<html>404 Not Found</html>')
        )
        expect(Honeybadger).to receive(:notify).with(
          instance_of(RestClient::NotFound),
          hash_including(context: hash_including(endpoint: 'https://ieducar.example.com/api/v2/notas'))
        )

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, '404 Not Found')
      end
    end

    context 'when the i-Educar fails to save the score (500)' do
      it 'keeps the rest-client text the worker uses to retry' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::InternalServerError, 500,
            '{"message":"Não foi possível salvar as notas para o aluno e turma informados. (erro)"}'
          )
        )
        allow(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, /\A500 Internal Server Error - /)
      end
    end
  end
end
