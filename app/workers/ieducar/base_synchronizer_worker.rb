class BaseSynchronizerWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, retry: 3, dead: false, queue: :synchronizer

  sidekiq_retries_exhausted do |msg, exception|
    params = msg['args'].first.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      unity = exception.try(:record).try(:unity)
      unity ||= exception.try(:record).try(:school_calendar).try(:unity)
      unity = "Escola: #{unity.api_code} - #{unity.name}, " if unity.present?
      classroom = exception.try(:record).try(:classroom)
      classroom ||= Classroom.find_by(id: exception.try(:record).try(:classroom_id))
      classroom = "Turma: #{classroom.api_code} - #{classroom.description}, " if classroom.present?
      exception_message = "#{unity}#{classroom}#{exception.message}"

      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      synchronization.mark_as_error!(
        I18n.t('ieducar_api.error.messages.sync_error'),
        exception_message
      )
    end

    Honeybadger.notify(exception)
  end
end
