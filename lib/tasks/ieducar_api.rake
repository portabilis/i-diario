namespace :ieducar_api do
  desc 'I-Educar API synchronization'
  task synchronize: :environment do
    IeducarSynchronizerWorker.perform_async
  end

  desc 'Cancela envio de notas travados há 1 dia ou mais'
  task cancel: :environment do
    Entity.active.each do |entity|
      entity.using_connection do
        postings = IeducarApiExamPosting.where(status: :started).
          where('created_at < ?', 1.day.ago)

        postings.each do |posting|
          posting.add_error!(I18n.t('ieducar_api.error.messages.sync_error'),
                             'Processo parado pelo sistema pois estava travado.')
          posting.mark_as_error!
        end
      end
    end
  end
end
