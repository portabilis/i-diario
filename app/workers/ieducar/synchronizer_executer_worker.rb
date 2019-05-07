class SynchronizerExecuterWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, retry: 3, dead: false

  sidekiq_retries_exhausted do |msg, exception|
    params = msg['args']

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      synchronization.mark_as_error!(
        I18n.t('ieducar_api.error.messages.sync_error'),
        exception.message
      )
    end
  end

  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      worker_batch = WorkerBatch.find(params[:worker_batch_id])

      begin
        params[:klass].constantize.synchronize!(
          params.slice(
            :entity_id,
            :worker_state_id,
            :year,
            :unity_api_code,
            :filtered_by_year,
            :filtered_by_unity
          ).merge(
            synchronization: synchronization,
            worker_batch: worker_batch
          )
        )
      rescue Sidekiq::Shutdown => error
        raise error
      rescue StandardError => error
        if error.message != '502 Bad Gateway'
          synchronization.mark_as_error!(I18n.t('ieducar_api.error.messages.sync_error'), error.message)
        end

        raise error
      end
    end
  end
end
