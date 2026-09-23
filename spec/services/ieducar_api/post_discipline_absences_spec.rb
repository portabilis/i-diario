require 'rails_helper'

# O tratamento de status, retry e autenticação é o de IeducarApi::V2Base, coberto em
# post_general_absences_spec.rb; aqui ficam o contrato do endpoint de faltas por componente e as
# recusas próprias dele.
RSpec.describe IeducarApi::PostDisciplineAbsences, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:configuration) do
    build(:ieducar_api_configuration, :with_api_security_token, url: 'https://ieducar.example.com')
  end
  let(:token) { configuration.api_security_token }
  let(:service) { described_class.new(configuration) }
  let(:params) { { etapa: 2, turma_id: '4502', aluno_id: '1234', componente_id: '17', faltas: 3 } }

  def http_error(error_class, status, body)
    error_class.new(double(code: status, body: body), status)
  end

  describe '#send_post' do
    context 'with local validation (no HTTP call)' do
      it 'requires the discipline' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:componente_id))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar o componente curricular')
      end

      it 'rejects a non numeric knowledge area instead of dropping it' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.merge(area_do_conhecimento_id: 'abc'))
        }.to raise_error(
          IeducarApi::Base::ApiError,
          'O valor informado para a área do conhecimento não é um número inteiro'
        )
      end
    end

    context 'on success' do
      it 'posts a flat payload to the discipline endpoint authenticated by the shared token' do
        expect(RestClient::Request).to receive(:execute).with(
          method: :post,
          url: 'https://ieducar.example.com/api/v2/falta-componente',
          open_timeout: described_class::OPEN_TIMEOUT,
          read_timeout: described_class::READ_TIMEOUT,
          payload: { turma_id: 4502, aluno_id: 1234, etapa: 2, faltas: 3, componente_id: 17 }.to_json,
          headers: { token: token, content_type: :json, accept: :json }
        ).and_return(double(code: 201, body: '{"message":"Falta por componente salva com sucesso."}'))

        result = service.send_post(params)

        expect(result).to eq(
          'msgs' => [{ 'msg' => 'Falta por componente salva com sucesso.' }],
          'any_error_msg' => false
        )
      end

      # O i-Educar grava a falta no primeiro componente agrupado da área e zera os demais.
      it 'sends the knowledge area of a grouped discipline' do
        expect(RestClient::Request).to receive(:execute).with(
          hash_including(
            payload: {
              turma_id: 4502, aluno_id: 1234, etapa: 2, faltas: 3, componente_id: 17, area_do_conhecimento_id: 8
            }.to_json
          )
        ).and_return(double(code: 201, body: '{"message":"Falta por componente salva com sucesso."}'))

        service.send_post(params.merge(area_do_conhecimento_id: 8))
      end

      it 'sends zero absences instead of skipping the discipline' do
        expect(RestClient::Request).to receive(:execute).with(
          hash_including(payload: { turma_id: 4502, aluno_id: 1234, etapa: 2, faltas: 0, componente_id: 17 }.to_json)
        ).and_return(double(code: 201, body: '{}'))

        result = service.send_post(params.merge(faltas: 0))

        expect(result['msgs']).to eq([{ 'msg' => 'Faltas postadas com sucesso!' }])
      end
    end

    context 'when the i-Educar finds no eligible registration (422 on aluno_id)' do
      it 'logs it with the discipline, without a notice for the teacher' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::UnprocessableEntity, 422,
            '{"message":"Matrícula não encontrada para o aluno e turma informados.",' \
            '"errors":{"aluno_id":["Matrícula não encontrada para o aluno e turma informados."]}}'
          )
        )
        expect(Honeybadger).not_to receive(:notify)
        expect(Rails.logger).to receive(:warn).with(
          /\[falta-componente\] matrícula recusada .* etapa: 2, faltas: 3, componente: 17, status: 422/
        )

        result = service.send_post(params)

        expect(result).to eq('msgs' => [], 'any_error_msg' => false)
      end
    end

    # Recusas de negócio: se repetem a cada aluno enquanto a divergência existir, então viram aviso
    # no envio sem abrir um incidente por aluno.
    [
      'A regra da turma 4502 não permite lançamento de faltas por componente.',
      'Componente curricular de código 17 não existe para a turma 4502.',
      'Não foi possível encontrar componentes dessa turma agrupados para a área do conhecimento informada.'
    ].each do |message|
      it "becomes a warning when the i-Educar answers: #{message}" do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::UnprocessableEntity, 422, { message: message }.to_json)
        )
        expect(Honeybadger).not_to receive(:notify)

        result = service.send_post(params)

        expect(result).to eq(
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
            '{"message":"The given data was invalid.",' \
            '"errors":{"etapa":["O campo etapa não pode ser superior a 4."]}}'
          )
        )
        expect(Honeybadger).to receive(:notify)

        result = service.send_post(params.merge(etapa: 5))

        expect(result['error']).to eq('message' => 'O campo etapa não pode ser superior a 4.')
      end
    end

    context 'when the i-Educar does not publish the endpoint yet (404 without a body)' do
      it 'fails hard' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(RestClient::NotFound, 404, '<html>404 Not Found</html>')
        )
        expect(Honeybadger).to receive(:notify).with(
          instance_of(IeducarApi::Base::GenericError),
          hash_including(context: hash_including(endpoint: 'https://ieducar.example.com/api/v2/falta-componente'))
        )

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, /resposta não reconhecida/)
      end
    end

    context 'when the i-Educar fails to save the absences (500)' do
      it 'preserves the database message so the worker can retry a duplicate key' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::InternalServerError, 500,
            '{"message":"Não foi possível salvar a falta por componente para o aluno e turma informados. ' \
            '(SQLSTATE[23505]: Unique violation: 7 ERROR: duplicate key value violates unique ' \
            'constraint \\"falta_componente_curricular_pkey\\")"}'
          )
        )
        allow(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError) { |error|
          expect(
            Ieducar::SendPostWorker::RETRY_ERRORS.any? { |retry_error| error.message.include?(retry_error) }
          ).to eq(true)
        }
      end
    end
  end
end
