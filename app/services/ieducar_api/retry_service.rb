module IeducarApi
  class RetryService
    MAX_RETRY_COUNT = 10

    def initialize(worker_class)
      @worker_class = worker_class
    end

    def schedule_retry(error, entity_id, posting_id, params, info, queue, retry_count)
      return false if retry_count >= MAX_RETRY_COUNT
      return false unless error.is_a?(IeducarApi::ErrorHandlerService::NetworkError)

      delay = calculate_delay(retry_count)

      worker_class.set(queue: queue).perform_in(
        delay,
        entity_id,
        posting_id,
        params,
        info,
        queue,
        retry_count + 1
      )

      true
    end

    def log_retry_attempt(information, params, posting_id, entity_id)
      Rails.logger.info(
        key: 'Ieducar::SendPostWorker#perform',
        info: information,
        params: params,
        posting_id: posting_id,
        entity_id: entity_id
      )
    end

    private

    attr_reader :worker_class

    def calculate_delay(retry_count)
      ((retry_count + 1) * 2).seconds
    end
  end
end
