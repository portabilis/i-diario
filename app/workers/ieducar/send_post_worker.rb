module Ieducar
  class SendPostWorker
    class IeducarException < StandardError; end

    extend Ieducar::SendPostPerformer
    include Ieducar::SendPostPerformer
    include Sidekiq::Worker

    sidekiq_options retry: 2, dead: false

    sidekiq_retries_exhausted do |msg, ex|
      args = msg['args'][0..-3]

      performer(*args) do |posting, _, _|
        # Só NÃO envia para o Honeybadger se for erro de validação
        unless IeducarApi::ErrorHandlerService.validation_error?(ex)
          Honeybadger.notify(ex)
        end

        if !posting.error_message?
          custom_error = "args: #{msg['args'].inspect}, error: #{ex.message}"

          posting.add_error!(
            I18n.t('ieducar_api.error.messages.post_error'),
            custom_error
          )
        end
      end
    end

    def perform(entity_id, posting_id, params, info, queue, retry_count)
      Honeybadger.context(posting_id: posting_id)

      performer(entity_id, posting_id, params, info) do |posting, params|
        IeducarApi::PostRequestService.new(posting).execute(params, info)
      rescue IeducarApi::ErrorHandlerService::RetryableError => error
        handle_retryable_error(error, entity_id, posting_id, params, info, queue, retry_count)
        retry
      rescue IeducarApi::ErrorHandlerService::NetworkError => error
        handle_network_error(error, entity_id, posting_id, params, info, queue, retry_count)
      end
    end

    private

    def handle_retryable_error(_error, entity_id, posting_id, params, info, _queue, _retry_count)
      information = IeducarApi::InfoMessageBuilder.new(info).build
      retry_service.log_retry_attempt(information, params, posting_id, entity_id)
    end

    def handle_network_error(error, entity_id, posting_id, params, info, queue, retry_count)
      return if retry_service.schedule_retry(error, entity_id, posting_id, params, info, queue, retry_count)

      raise error
    end

    def retry_service
      @retry_service ||= IeducarApi::RetryService.new(self.class)
    end
  end
end
