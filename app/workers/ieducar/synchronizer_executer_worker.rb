class SynchronizerExecuterWorker < BaseSynchronizerWorker
  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      return unless synchronization.started?

      worker_batch = WorkerBatch.find(params[:worker_batch_id])

      params[:klass].constantize.synchronize!(
        synchronizer_params(params, synchronization, worker_batch)
      )
    rescue IeducarApi::Base::GenericError, IeducarApi::Base::ApiError => error
      synchronization.mark_as_error!(error.message)

      known_errors = [
        'Chave de acesso inválida!',
        'Desculpe, mas não existem escolas cadastradas',
        'URL do i-Educar informada não é válida.'
      ]

      raise error unless known_errors.any? { |msg| error.message.include?(msg) }
    end
  end

  private

  def synchronizer_params(params, synchronization, worker_batch)
    params.slice(
      :entity_id,
      :worker_state_id,
      :year,
      :unity_api_code,
      :filtered_by_year,
      :filtered_by_unity,
      :current_years
    ).merge(
      synchronization: synchronization,
      worker_batch: worker_batch
    )
  end

  def last_synchronization_date
    datetime = @last_synchronization_date ||= current_api_configuration.synchronized_at
    datetime&.to_date&.to_s
  end
end
