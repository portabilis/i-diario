require 'rails_helper'

# O tratamento de status, retry e autenticação é o de IeducarApi::V2Base, coberto em
# post_general_absences_spec.rb; aqui ficam os endpoints de parecer descritivo e as recusas deles.
RSpec.describe IeducarApi::PostOpinions, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:configuration) do
    build(:ieducar_api_configuration, :with_api_security_token, url: 'https://ieducar.example.com')
  end
  let(:token) { configuration.api_security_token }

  def http_error(error_class, status, body)
    error_class.new(double(code: status, body: body), status)
  end

  def saved
    double(code: 201, body: '{"message":"Parecer salvo com sucesso."}')
  end

  describe '.for_payload' do
    # O payload diz o tipo de parecer: os anuais não têm etapa, e os gerais não têm componente.
    {
      { etapa: 2 } => IeducarApi::PostOpinionsByStep,
      { etapa: 2, componente_id: '17' } => IeducarApi::PostOpinionsByStepAndDiscipline,
      {} => IeducarApi::PostOpinionsByYear,
      { componente_id: '17' } => IeducarApi::PostOpinionsByYearAndDiscipline
    }.each do |fields, api_class|
      it "picks #{api_class.name.demodulize} for #{fields.keys.inspect}" do
        params = { 'turma_id' => '4502', 'aluno_id' => '1234', 'parecer' => 'Texto' }.merge(fields.stringify_keys)

        expect(described_class.for_payload(configuration, params)).to be_a(api_class)
      end
    end
  end

  describe '#send_post' do
    [
      [
        IeducarApi::PostOpinionsByStep,
        { etapa: 2 },
        '/api/v2/pareceres-por-etapa-geral',
        { turma_id: 4502, aluno_id: 1234, etapa: 2, parecer: 'Texto' }
      ],
      [
        IeducarApi::PostOpinionsByStepAndDiscipline,
        { etapa: 2, componente_id: '17' },
        '/api/v2/pareceres-por-etapa-e-componente',
        { turma_id: 4502, aluno_id: 1234, etapa: 2, componente_id: 17, parecer: 'Texto' }
      ],
      [
        IeducarApi::PostOpinionsByYear,
        {},
        '/api/v2/pareceres-anual-geral',
        { turma_id: 4502, aluno_id: 1234, parecer: 'Texto' }
      ],
      [
        IeducarApi::PostOpinionsByYearAndDiscipline,
        { componente_id: '17' },
        '/api/v2/pareceres-anual-por-componente',
        { turma_id: 4502, aluno_id: 1234, componente_id: 17, parecer: 'Texto' }
      ]
    ].each do |api_class, fields, path, payload|
      it "posts a flat payload to #{path} authenticated by the shared token" do
        expect(RestClient::Request).to receive(:execute).with(
          method: :post,
          url: "https://ieducar.example.com#{path}",
          open_timeout: described_class::OPEN_TIMEOUT,
          read_timeout: described_class::READ_TIMEOUT,
          payload: payload.to_json,
          headers: { token: token, content_type: :json, accept: :json }
        ).and_return(saved)

        result = api_class.new(configuration).send_post(
          { turma_id: '4502', aluno_id: '1234', parecer: 'Texto' }.merge(fields)
        )

        expect(result).to eq('msgs' => [{ 'msg' => 'Parecer salvo com sucesso.' }], 'any_error_msg' => false)
      end
    end

    context 'with a step and discipline opinion' do
      let(:service) { IeducarApi::PostOpinionsByStepAndDiscipline.new(configuration) }
      let(:params) { { etapa: 2, turma_id: '4502', aluno_id: '1234', componente_id: '17', parecer: 'Texto' } }

      it 'requires the discipline' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:componente_id))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar o componente curricular')
      end

      it 'requires the opinion field, so a missing value never clears the opinion by accident' do
        expect(RestClient::Request).not_to receive(:execute)

        expect {
          service.send_post(params.except(:parecer))
        }.to raise_error(IeducarApi::Base::ApiError, 'É necessário informar o parecer')
      end

      # O i-Educar trata o texto vazio como pedido para limpar o parecer já lançado.
      [nil, ''].each do |blank_opinion|
        it "sends an empty opinion to clear it when the value is #{blank_opinion.inspect}" do
          expect(RestClient::Request).to receive(:execute).with(
            hash_including(
              payload: { turma_id: 4502, aluno_id: 1234, etapa: 2, componente_id: 17, parecer: '' }.to_json
            )
          ).and_return(saved)

          service.send_post(params.merge(parecer: blank_opinion))
        end
      end

      it 'falls back to the default message when the body has none' do
        allow(RestClient::Request).to receive(:execute).and_return(double(code: 201, body: '{}'))

        expect(service.send_post(params)['msgs']).to eq([{ 'msg' => 'Pareceres postados com sucesso!' }])
      end

      it 'logs a registration refused by the i-Educar without a notice for the teacher' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::UnprocessableEntity, 422,
            '{"message":"Matrícula não encontrada para o aluno e turma informados.",' \
            '"errors":{"aluno_id":["Matrícula não encontrada para o aluno e turma informados."]}}'
          )
        )
        expect(Honeybadger).not_to receive(:notify)
        expect(Rails.logger).to receive(:warn).with(
          /\[pareceres-por-etapa-e-componente\] matrícula recusada .* etapa: 2, componente: 17, status: 422/
        )

        expect(service.send_post(params)).to eq('msgs' => [], 'any_error_msg' => false)
      end

      # Recusas de regra: se repetem a cada aluno enquanto a divergência existir, então viram aviso
      # no envio sem abrir um incidente por aluno.
      [
        'A regra da turma 4502 não permite lançamento de pareceres por etapa e componente.',
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

      it 'keeps the rest-client text the worker uses to retry on a 500' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(
            RestClient::InternalServerError, 500,
            '{"message":"Não foi possível salvar o parecer para o aluno e turma informados. (erro)"}'
          )
        )
        allow(Honeybadger).to receive(:notify)

        expect {
          service.send_post(params)
        }.to raise_error(IeducarApi::Base::GenericError, /\A500 Internal Server Error - /)
      end
    end

    context 'with a yearly opinion' do
      it 'does not require a step' do
        expect(RestClient::Request).to receive(:execute).and_return(saved)

        IeducarApi::PostOpinionsByYear.new(configuration)
                                      .send_post(turma_id: '4502', aluno_id: '1234', parecer: 'Texto')
      end
    end
  end
end
