require 'rails_helper'

RSpec.describe IeducarApi::RetryService, type: :service do
  let(:worker_class) { double('WorkerClass') }
  let(:retry_service) { described_class.new(worker_class) }
  let(:error) {
 IeducarApi::ErrorHandlerService::NetworkError.new(StandardError.new('Network error'), 'Test info')
  }
  let(:entity_id) { 1 }
  let(:posting_id) { 123 }
  let(:params) { { test: 'data' } }
  let(:info) { { student: 'John Doe' } }
  let(:queue) { 'default' }
  let(:retry_count) { 0 }

  describe '#initialize' do
    it 'sets the worker class' do
      service = described_class.new(worker_class)
      expect(service.send(:worker_class)).to eq(worker_class)
    end
  end

  describe '#schedule_retry' do
    let(:worker_double) { double('Worker') }

    before do
      allow(worker_class).to receive(:set).with(queue: queue).and_return(worker_double)
      allow(worker_double).to receive(:perform_in)
    end

    context 'when retry count is below maximum' do
      context 'when error is a NetworkError' do
        it 'schedules a retry job' do
          expect(worker_double).to receive(:perform_in).with(
            2.seconds, # (0 + 1) * 2 = 2 seconds for retry_count 0
            entity_id,
            posting_id,
            params,
            info,
            queue,
            1 # retry_count + 1
          )

          result = retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue, retry_count)
          expect(result).to be true
        end

        it 'calculates correct delay for different retry counts' do
          expect(worker_double).to receive(:perform_in).with(6.seconds, anything, anything, anything, anything,
anything, anything)
          retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue, 2)
        end
      end

      context 'when error is not a NetworkError' do
        let(:other_error) {
 IeducarApi::ErrorHandlerService::RetryableError.new(StandardError.new('Other error'), 'Test info')
        }

        it 'does not schedule retry and returns false' do
          expect(worker_double).not_to receive(:perform_in)
          result = retry_service.schedule_retry(other_error, entity_id, posting_id, params, info, queue,
retry_count)
          expect(result).to be false
        end
      end
    end

    context 'when retry count reaches maximum' do
      let(:max_retry_count) { described_class::MAX_RETRY_COUNT }

      it 'does not schedule retry and returns false' do
        expect(worker_double).not_to receive(:perform_in)
        result = retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue, max_retry_count)
        expect(result).to be false
      end
    end

    context 'when retry count exceeds maximum' do
      let(:over_max_retry_count) { described_class::MAX_RETRY_COUNT + 1 }

      it 'does not schedule retry and returns false' do
        expect(worker_double).not_to receive(:perform_in)
        result = retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue,
over_max_retry_count)
        expect(result).to be false
      end
    end
  end

  describe '#log_retry_attempt' do
    let(:information) { 'Test information message' }

    it 'logs retry attempt with correct parameters' do
      expect(Rails.logger).to receive(:info).with({
                                                    key: 'Ieducar::SendPostWorker#perform',
        info: information,
        params: params,
        posting_id: posting_id,
        entity_id: entity_id
                                                  })

      retry_service.log_retry_attempt(information, params, posting_id, entity_id)
    end
  end

  describe '#calculate_delay (private method)' do
    it 'calculates correct delay for different retry counts' do
      # Testando método privado através de reflexão para garantir a lógica
      expect(retry_service.send(:calculate_delay, 0)).to eq(2.seconds)
      expect(retry_service.send(:calculate_delay, 1)).to eq(4.seconds)
      expect(retry_service.send(:calculate_delay, 2)).to eq(6.seconds)
      expect(retry_service.send(:calculate_delay, 5)).to eq(12.seconds)
    end
  end

  describe 'MAX_RETRY_COUNT constant' do
    it 'is set to 10' do
      expect(described_class::MAX_RETRY_COUNT).to eq(10)
    end
  end

  describe 'integration scenarios' do
    let(:worker_double) { double('Worker') }

    before do
      allow(worker_class).to receive(:set).with(queue: queue).and_return(worker_double)
      allow(worker_double).to receive(:perform_in)
    end

    context 'when scheduling multiple retries' do
      it 'increases delay progressively' do
        # Primeira tentativa (retry_count = 0)
        expect(worker_double).to receive(:perform_in).with(2.seconds, anything, anything, anything, anything,
anything, 1)
        retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue, 0)

        # Segunda tentativa (retry_count = 1)
        expect(worker_double).to receive(:perform_in).with(4.seconds, anything, anything, anything, anything,
anything, 2)
        retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue, 1)

        # Terceira tentativa (retry_count = 2)
        expect(worker_double).to receive(:perform_in).with(6.seconds, anything, anything, anything, anything,
anything, 3)
        retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue, 2)
      end
    end

    context 'when reaching maximum retry attempts' do
      it 'stops scheduling retries' do
        # Tenta agendar no limite máximo
        expect(worker_double).not_to receive(:perform_in)
        result = retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue, 10)
        expect(result).to be false
      end
    end
  end
end
