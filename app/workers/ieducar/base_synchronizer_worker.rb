class BaseSynchronizerWorker
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
end
