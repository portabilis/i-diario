class SynchronizationOrchestrator
  def initialize(worker_batch, current_worker_name, params)
    @worker_batch = worker_batch
    @current_worker_name = current_worker_name
    @params = params
  end

  def can_synchronize?
    by_year = SynchronizationConfigs.config(current_worker_name, :by_year)
    by_unity = SynchronizationConfigs.config(current_worker_name, :by_unity)

    return false if worker_initialized?(current_worker_name, by_year, by_unity)

    can_synchronize_worker?(current_worker_name)
  end

  def enqueue_next
    WorkerState.first.with_lock do
      SynchronizationConfigs.dependents(current_worker_name).each do |klass|
        next unless can_synchronize_worker?(klass)

        call_worker(SynchronizationConfigs.configs(klass))
      end
    end
  end

  private

  attr_accessor :worker_batch, :current_worker_name, :params

  def can_synchronize_worker?(worker_name)
    valid_year = params[:year].to_s.split(',').size == 1
    current_worker_by_year = SynchronizationConfigs.config(worker_name, :by_year) && valid_year
    current_worker_by_unity = SynchronizationConfigs.config(worker_name, :by_unity)

    count = SynchronizationConfigs.dependencies(worker_name).select { |klass|
      by_year = SynchronizationConfigs.config(klass, :by_year) && current_worker_by_year
      by_unity = SynchronizationConfigs.config(klass, :by_unity) && current_worker_by_unity

      worker_completed?(klass, by_year, by_unity)
    }.size

    count == SynchronizationConfigs.dependencies(worker_name).size
  end

  def worker_initialized?(worker_name, by_year, by_unity, status = nil)
    worker_states = WorkerState.by_worker_batch_id(worker_batch.id)
                               .by_kind(worker_name)

    worker_states = worker_states.by_status(status) if status.present?
    worker_states = worker_states.by_meta_data(:year, params[:year]) if by_year && params[:year].present?

    if by_unity && params[:unity_api_code].present?
      worker_states = worker_states.by_meta_data(:unity_api_code, params[:unity_api_code])
    end

    worker_states.exists?
  end

  def worker_completed?(worker_name, by_year, by_unity)
    worker_initialized?(worker_name, by_year, by_unity, ApiSynchronizationStatus::COMPLETED)
  end

  def call_worker(synchronizer)
    SynchronizerBuilderWorker.perform_async(
      params.slice(
        :entity_id
      ).merge(
        klass: synchronizer[:klass],
        synchronization_id: params[:synchronization].id,
        worker_batch_id: params[:worker_batch].id,
        years: params[:year].to_s.split(','),
        unities_api_code: params[:unity_api_code].to_s.split(','),
        filtered_by_year: synchronizer[:by_year],
        filtered_by_unity: synchronizer[:by_unity]
      )
    )
  end
end
