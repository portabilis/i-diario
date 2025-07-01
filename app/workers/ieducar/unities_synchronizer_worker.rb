class UnitiesSynchronizerWorker < BaseSynchronizerWorker
  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.started.find_by(id: params[:synchronization_id])
      if synchronization
        @worker_batch = synchronization.worker_batch

        params = build_params(
          params[:entity_id],
          worker_state_id,
          synchronization.id,
          @worker_batch.id,
          params[:current_years]
        )
        UnitiesSynchronizer.new(params).synchronize!
      end
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

  def worker_state_id
    WorkerState.create!(
      worker_batch: @worker_batch,
      kind: UnitiesSynchronizer.to_s
    )
  end

  def build_params(entity_id, worker_state_id, synchronization_id, worker_batch_id, current_years)
    {
      entity_id: entity_id,
      worker_state_id: worker_state_id,
      year: [],
      unity_api_code: [],
      filtered_by_year: false,
      filtered_by_unity: false,
      synchronization_id: synchronization_id,
      worker_batch_id: worker_batch_id,
      current_years: current_years
    }
  end
end
