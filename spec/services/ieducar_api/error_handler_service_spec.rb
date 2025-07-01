require 'rails_helper'

RSpec.describe IeducarApi::ErrorHandlerService, type: :service do
  let(:posting) { double('Posting') }
  let(:error_handler) { described_class.new(posting) }
  let(:information) { 'Turma: 1A, Aluno: João Silva' }

  describe 'custom exceptions' do
    describe 'PostRequestError' do
      let(:original_error) { StandardError.new('Original error message') }
      let(:post_request_error) { described_class::PostRequestError.new(original_error, information) }

      it 'stores original error and information' do
        expect(post_request_error.original_error).to eq(original_error)
        expect(post_request_error.information).to eq(information)
      end

      it 'formats message correctly' do
        expected_message = "#{information} Erro: #{original_error.message}"
        expect(post_request_error.message).to eq(expected_message)
      end
    end

    describe 'RetryableError' do
      it 'inherits from PostRequestError' do
        expect(described_class::RetryableError).to be < described_class::PostRequestError
      end
    end

    describe 'NetworkError' do
      it 'inherits from PostRequestError' do
        expect(described_class::NetworkError).to be < described_class::PostRequestError
      end
    end

    describe 'ValidationError' do
      it 'inherits from PostRequestError' do
        expect(described_class::ValidationError).to be < described_class::PostRequestError
      end
    end
  end

  describe 'constants' do
    describe 'RETRY_ERRORS' do
      it 'contains expected retry error patterns' do
        expect(described_class::RETRY_ERRORS).to include(
          %(duplicate key value violates unique constraint "modules_nota_aluno_matricula_id_unique"),
          %(duplicate key value violates unique constraint "modules_parecer_aluno_matricula_id_unique"),
          %(duplicate key value violates unique constraint "falta_componente_curricular_pkey"),
          %(duplicate key value violates unique constraint "modules_falta_aluno_matricula_id_unique"),
          %(duplicate key value violates unique constraint "falta_geral_pkey"),
          %(duplicate key value violates unique constraint "nota_componente_curricular_pkey"),
          %(duplicate key value violates unique constraint "parecer_geral_pkey")
        )
      end

      it 'is frozen' do
        expect(described_class::RETRY_ERRORS).to be_frozen
      end
    end

    describe 'VALIDATION_ERRORS' do
      it 'contains expected validation error patterns' do
        expect(described_class::VALIDATION_ERRORS).to include(
          'não é um valor numérico',
          'Exception: O parâmetro',
          'não pode estar vazio',
          'é obrigatório',
          'valor inválido',
          'formato inválido',
          'deve ser numérico',
          'URL do i-Educar informada não é válida'
        )
      end

      it 'is frozen' do
        expect(described_class::VALIDATION_ERRORS).to be_frozen
      end
    end
  end

  describe '#initialize' do
    it 'sets the posting' do
      service = described_class.new(posting)
      expect(service.send(:posting)).to eq(posting)
    end
  end

  describe '#handle' do
    context 'when error should be retried' do
      let(:retry_error) {
 StandardError.new('duplicate key value violates unique constraint "modules_nota_aluno_matricula_id_unique"')
      }      

      it 'raises RetryableError' do
        expect { error_handler.handle(retry_error, information) }
          .to raise_error(described_class::RetryableError) do |error|
            expect(error.original_error).to eq(retry_error)
            expect(error.information).to eq(information)
          end
      end
    end

    context 'when error is a validation error' do
      let(:validation_error) { StandardError.new('não é um valor numérico') }

      before do
        allow(posting).to receive(:add_error!)
        allow(I18n).to receive(:t).with('ieducar_api.error.messages.post_error').and_return('Erro na requisição')
      end

      it 'adds error to posting without raising exception' do
        expect(posting).to receive(:add_error!).with(
          'Erro na requisição',
          "#{information} Erro: #{validation_error.message}"
        )

        expect { error_handler.handle(validation_error, information) }.not_to raise_error
      end
    end

    context 'when error is a network error' do
      let(:network_error) { double('NetworkError') }

      before do
        allow(network_error).to receive(:is_a?).with(IeducarApi::Base::NetworkException).and_return(true)
        allow(network_error).to receive(:message).and_return('Network connection failed')
      end

      it 'raises NetworkError' do
        expect { error_handler.handle(network_error, information) }
          .to raise_error(described_class::NetworkError) do |error|
            expect(error.original_error).to eq(network_error)
            expect(error.information).to eq(information)
          end
      end
    end

    context 'when error is a generic error' do
      let(:generic_error) { StandardError.new('Generic error message') }

      it 'raises StandardError with formatted message' do
        expect { error_handler.handle(generic_error, information) }
          .to raise_error(StandardError, "#{information} Erro: #{generic_error.message}")
      end
    end
  end

  describe '.validation_error?' do
    context 'when error message contains validation error pattern' do
      it 'returns true for numeric validation error' do
        error = StandardError.new('O campo não é um valor numérico')
        expect(described_class.validation_error?(error)).to be true
      end

      it 'returns true for parameter validation error' do
        error = StandardError.new('Exception: O parâmetro nome é obrigatório')
        expect(described_class.validation_error?(error)).to be true
      end

      it 'returns true for empty field validation error' do
        error = StandardError.new('O campo não pode estar vazio')
        expect(described_class.validation_error?(error)).to be true
      end

      it 'returns true for URL validation error' do
        error = StandardError.new('URL do i-Educar informada não é válida')
        expect(described_class.validation_error?(error)).to be true
      end
    end

    context 'when error message does not contain validation error pattern' do
      it 'returns false' do
        error = StandardError.new('Database connection failed')
        expect(described_class.validation_error?(error)).to be false
      end
    end
  end

  describe 'private methods' do
    describe '#should_retry_error?' do
      context 'when error message contains retry pattern' do
        it 'returns true for unique constraint violations' do
          error = StandardError.new('duplicate key value violates unique constraint "modules_nota_aluno_matricula_id_unique"')
          expect(error_handler.send(:should_retry_error?, error)).to be true
        end

        it 'returns true for parecer constraint violations' do
          error = StandardError.new('duplicate key value violates unique constraint "modules_parecer_aluno_matricula_id_unique"')
          expect(error_handler.send(:should_retry_error?, error)).to be true
        end

        it 'returns true for falta constraint violations' do
          error = StandardError.new('duplicate key value violates unique constraint "falta_componente_curricular_pkey"')
          expect(error_handler.send(:should_retry_error?, error)).to be true
        end
      end

      context 'when error message does not contain retry pattern' do
        it 'returns false' do
          error = StandardError.new('Some other database error')
          expect(error_handler.send(:should_retry_error?, error)).to be false
        end
      end
    end

    describe '#validation_error?' do
      it 'delegates to class method' do
        error = StandardError.new('não é um valor numérico')
        expect(described_class).to receive(:validation_error?).with(error)
        error_handler.send(:validation_error?, error)
      end
    end

    describe '#network_error?' do
      context 'when error is a NetworkException' do
        let(:network_error) { double('NetworkError') }

        before do
          allow(network_error).to receive(:is_a?).with(IeducarApi::Base::NetworkException).and_return(true)
        end

        it 'returns true' do
          expect(error_handler.send(:network_error?, network_error)).to be true
        end
      end

      context 'when error is not a NetworkException' do
        let(:other_error) { StandardError.new('Other error') }

        it 'returns false' do
          expect(error_handler.send(:network_error?, other_error)).to be false
        end
      end
    end
  end

  describe 'integration scenarios' do
    context 'when handling multiple error types in sequence' do
      before do
        allow(posting).to receive(:add_error!)
        allow(I18n).to receive(:t).with('ieducar_api.error.messages.post_error').and_return('Erro na requisição')
      end

      it 'handles each error type appropriately' do
        # Retry error
        retry_error = StandardError.new('duplicate key value violates unique constraint "modules_nota_aluno_matricula_id_unique"')
        expect { error_handler.handle(retry_error, information) }
          .to raise_error(described_class::RetryableError)

        # Validation error
        validation_error = StandardError.new('não é um valor numérico')
        expect { error_handler.handle(validation_error, information) }.not_to raise_error

        # Network error
        network_error = double('NetworkError')
        allow(network_error).to receive(:is_a?).with(IeducarApi::Base::NetworkException).and_return(true)
        allow(network_error).to receive(:message).and_return('Network failed')
        expect { error_handler.handle(network_error, information) }
          .to raise_error(described_class::NetworkError)
      end
    end

    context 'when error message contains multiple patterns' do
      it 'prioritizes retry over validation' do
        # Error que contém tanto padrão de retry quanto validação
        mixed_error = StandardError.new('duplicate key value violates unique constraint "modules_nota_aluno_matricula_id_unique" não é um valor numérico')

        expect { error_handler.handle(mixed_error, information) }
          .to raise_error(described_class::RetryableError)
      end
    end
  end
end
