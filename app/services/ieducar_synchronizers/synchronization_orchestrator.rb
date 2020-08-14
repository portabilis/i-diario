class SynchronizationOrchestrator
  def initialize(worker_batch, current_worker_name, params)
    @worker_batch = worker_batch
    @current_worker_name = current_worker_name
    @params = params
  end

  def can_synchronize?
    config = SynchronizationConfigs.find(current_worker_name)
    by_year = config[:by_year]
    by_unity = config[:by_unity]

    return false if worker_initialized?(current_worker_name, by_year, by_unity)

    dependencies_solved?(current_worker_name, by_year, by_unity)
  end

  def enqueue_next
    SynchronizationConfigs.dependents_by_klass(current_worker_name).each do |klass|
      config = SynchronizationConfigs.find(klass)
      by_year = config[:by_year]
      by_unity = config[:by_unity]

      next if by_year && params[:year].blank?
      next if by_unity && params[:unity_api_code].blank?
      next if config[:only_simple_synchronization] && params[:synchronization].full_synchronization
      next unless dependencies_solved?(klass, by_year, by_unity)

      enqueue_job(config)
    end
  end

  private

  attr_accessor :worker_batch, :current_worker_name, :params

  def dependencies_solved?(worker_name, by_year, by_unity)
    dependencies_count = SynchronizationConfigs.dependencies_by_klass(worker_name).size

    completed_dependencies_count(worker_name, by_year, by_unity) == dependencies_count
  end

  def completed_dependencies_count(worker_name, current_worker_by_year, current_worker_by_unity)
    SynchronizationConfigs.dependencies_by_klass(worker_name).select { |klass|
      config = SynchronizationConfigs.find(klass)
      by_year = config[:by_year] && current_worker_by_year
      by_unity = config[:by_unity] && current_worker_by_unity

      worker_completed?(klass, by_year, by_unity)
    }.size
  end

  def worker_completed?(worker_name, by_year, by_unity)
    worker_states = initialized_worker_states_by(worker_name, by_year, by_unity)

    worker_states.by_status(ApiSynchronizationStatus::COMPLETED).exists?
  end

  def worker_initialized?(worker_name, by_year, by_unity)
    initialized_worker_states_by(worker_name, by_year, by_unity).exists?
  end

  def initialized_worker_states_by(worker_name, by_year, by_unity)
    worker_states = WorkerState.by_worker_batch_id(worker_batch.id)
                               .by_kind(worker_name)
    worker_states = worker_states.by_meta_data(:year, params[:year]) if by_year && params[:year].present?

    if by_unity && params[:unity_api_code].present?
      worker_states = worker_states.by_meta_data(:unity_api_code, params[:unity_api_code])
    end

    worker_states
  end

  def enqueue_job(synchronizer)
    SynchronizerBuilderWorker.perform_async(
      params.slice(
        :entity_id,
        :current_years
      ).merge(
        klass: synchronizer[:klass],
        synchronization_id: params[:synchronization].id,
        worker_batch_id: worker_batch.id,
        years: params[:year].to_s.split(','),
        unities_api_code: params[:unity_api_code].to_s.split(','),
        filtered_by_year: synchronizer[:by_year],
        filtered_by_unity: synchronizer[:by_unity]
      )
    )
  end
end
