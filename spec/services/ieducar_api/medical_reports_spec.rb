require 'rails_helper'

RSpec.describe IeducarApi::MedicalReports, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:configuration) do
    IeducarApiConfiguration.new(url: 'https://ieducar.example.com', api_security_token: 'shared-secret')
  end
  let(:service) { described_class.new(configuration) }
  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec', 'support', 'assets', 'document.pdf'), 'application/pdf'
    )
  end

  def http_error(status, body)
    RestClient::ExceptionWithResponse.new(double(code: status, body: body), status)
  end

  describe '#upload' do
    context 'with local validation (mirrors the i-Educar endpoint rules, no HTTP call)' do
      it 'rejects a missing file' do
        expect(RestClient::Request).not_to receive(:execute)

        result = service.upload(student_api_code: '123', file: nil)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Selecione um arquivo para enviar.')
        expect(result.http_status).to eq(:unprocessable_entity)
      end

      it 'rejects an extension outside the i-Educar whitelist' do
        csv = Rack::Test::UploadedFile.new(
          Rails.root.join('spec', 'fixtures', 'csv', 'bncc_empty.csv'), 'text/csv'
        )
        expect(RestClient::Request).not_to receive(:execute)

        result = service.upload(student_api_code: '123', file: csv)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Deve ser enviado um arquivo do tipo jpg, jpeg, png, pdf ou doc.')
        expect(result.http_status).to eq(:unprocessable_entity)
      end

      it 'rejects a file larger than 2MB' do
        allow(file).to receive(:size).and_return(described_class::MAX_FILE_SIZE + 1)
        expect(RestClient::Request).not_to receive(:execute)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Não são permitidos arquivos com mais de 2MB.')
        expect(result.http_status).to eq(:unprocessable_entity)
      end
    end

    context 'when the integration is not configured' do
      let(:configuration) { IeducarApiConfiguration.new(url: 'https://ieducar.example.com', api_security_token: '') }

      it 'fails without calling the i-Educar' do
        expect(RestClient::Request).not_to receive(:execute)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('A integração com o i-Educar não está configurada.')
        expect(result.http_status).to eq(:bad_gateway)
      end
    end

    context 'on success' do
      it 'posts the file to the api/v2 endpoint authenticated by the shared token' do
        expect(RestClient::Request).to receive(:execute).with(
          method: :post,
          url: 'https://ieducar.example.com/api/v2/aluno-laudo-upload',
          open_timeout: described_class::OPEN_TIMEOUT,
          read_timeout: described_class::READ_TIMEOUT,
          headers: { token: 'shared-secret' },
          payload: { multipart: true, aluno_id: '123', file: file }
        ).and_return(double(body: '{"message":"Laudo salvo com sucesso."}'))

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(true)
        expect(result.message).to eq('Laudo salvo com sucesso.')
        expect(result.http_status).to eq(:ok)
      end

      it 'falls back to the local success message when the i-Educar body has no message' do
        allow(RestClient::Request).to receive(:execute).and_return(double(body: '{}'))

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(true)
        expect(result.message).to eq('Laudo enviado para o cadastro do aluno no i-Educar.')
      end
    end

    context 'when the i-Educar rejects the upload (422)' do
      it 'relays the i-Educar validation message without notifying Honeybadger' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(422, '{"message":"Não são permitidos arquivos com mais de 2MB."}')
        )
        expect(Honeybadger).not_to receive(:notify)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Não são permitidos arquivos com mais de 2MB.')
        expect(result.http_status).to eq(:unprocessable_entity)
      end
    end

    context 'when the shared token diverges between the two systems (401)' do
      it 'explains the integration problem and notifies Honeybadger' do
        allow(RestClient::Request).to receive(:execute).and_raise(http_error(401, '{"message":"Unauthorized"}'))
        expect(Honeybadger).to receive(:notify)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message)
          .to eq('O i-Educar recusou o token da integração. Revise a configuração da API nos dois sistemas.')
        expect(result.http_status).to eq(:bad_gateway)
      end
    end

    context 'when the i-Educar does not offer the endpoint yet (404)' do
      it 'explains that the resource is missing and notifies Honeybadger' do
        allow(RestClient::Request).to receive(:execute).and_raise(http_error(404, ''))
        expect(Honeybadger).to receive(:notify)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('O i-Educar deste município ainda não oferece o envio de laudos.')
        expect(result.http_status).to eq(:bad_gateway)
      end
    end

    context 'when the i-Educar fails to persist the file (500)' do
      it 'shows the generic message and keeps the remote text in the Honeybadger context' do
        allow(RestClient::Request).to receive(:execute).and_raise(
          http_error(500, '{"message":"SQLSTATE[HY000] em /var/www/app/Services/FileService.php:41"}')
        )
        expect(Honeybadger).to receive(:notify).with(
          instance_of(RestClient::ExceptionWithResponse),
          hash_including(
            context: hash_including(
              remote_message: 'SQLSTATE[HY000] em /var/www/app/Services/FileService.php:41'
            )
          )
        )

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Não foi possível enviar o laudo ao i-Educar.')
        expect(result.http_status).to eq(:bad_gateway)
      end

      it 'does not send the file name to Honeybadger (laudo file names carry student data)' do
        allow(RestClient::Request).to receive(:execute).and_raise(http_error(500, '<html>oops</html>'))
        expect(Honeybadger).to receive(:notify) do |_error, options|
          expect(options[:context]).to include(file_extension: '.pdf', student_api_code: '123')
          expect(options[:context].keys).not_to include(:filename)
        end

        result = service.upload(student_api_code: '123', file: file)

        expect(result.message).to eq('Não foi possível enviar o laudo ao i-Educar.')
      end
    end

    context 'on a network failure' do
      it 'fails with the connection message on timeout' do
        allow(RestClient::Request).to receive(:execute)
          .and_raise(RestClient::Exceptions::ReadTimeout.new('Timed out reading data from server'))
        allow(Honeybadger).to receive(:notify)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Não foi possível conectar ao i-Educar. Tente novamente em instantes.')
        expect(result.http_status).to eq(:bad_gateway)
      end

      it 'fails with the connection message when the host is unreachable' do
        allow(RestClient::Request).to receive(:execute).and_raise(SocketError.new('getaddrinfo failed'))
        allow(Honeybadger).to receive(:notify)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Não foi possível conectar ao i-Educar. Tente novamente em instantes.')
      end

      it 'fails with the connection message when the i-Educar certificate is not valid' do
        allow(RestClient::Request).to receive(:execute)
          .and_raise(RestClient::SSLCertificateNotVerified.new('certificate verify failed'))
        allow(Honeybadger).to receive(:notify)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Não foi possível conectar ao i-Educar. Tente novamente em instantes.')
        expect(result.http_status).to eq(:bad_gateway)
      end

      it 'fails with the connection message on a generic TLS failure' do
        allow(RestClient::Request).to receive(:execute)
          .and_raise(OpenSSL::SSL::SSLError.new('wrong version number'))
        allow(Honeybadger).to receive(:notify)

        result = service.upload(student_api_code: '123', file: file)

        expect(result.success?).to eq(false)
        expect(result.message).to eq('Não foi possível conectar ao i-Educar. Tente novamente em instantes.')
      end
    end
  end
end
