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

    return false if worker_initialized?(current_worker_name, by_year, by_unity, params[:year])

    dependencies_solved?(current_worker_name, by_year, by_unity, params[:year])
  end

  def enqueue_next
    SynchronizationConfigs.dependents_by_klass(current_worker_name).each do |klass|
      enqueue_dependent(SynchronizationConfigs.find(klass))
    end
  end

  private

  attr_accessor :worker_batch, :current_worker_name, :params

  def enqueue_dependent(config)
    by_year = config[:by_year]
    by_unity = config[:by_unity]

    return if by_year && params[:year].blank?
    return if by_unity && params[:unity_api_code].blank?

    years_to_enqueue(by_year).each do |year|
      enqueue_job(config, year) if dependencies_solved?(config[:klass], by_year, by_unity, year)
    end
  end

  # Um sincronizador que não é filtrado por ano recebe todos os anos juntos em params[:year] ("2027,2026").
  # O dependente filtrado por ano é avaliado ano a ano: se esse sincronizador terminar depois da dependência
  # filtrada por ano, é ele quem precisa enfileirar o dependente de cada ano já liberado.
  def years_to_enqueue(by_year)
    return [params[:year]] unless by_year

    params[:year].to_s.split(',')
  end

  def dependencies_solved?(worker_name, by_year, by_unity, year)
    dependencies_count = SynchronizationConfigs.dependencies_by_klass(worker_name).size

    completed_dependencies_count(worker_name, by_year, by_unity, year) == dependencies_count
  end

  def completed_dependencies_count(worker_name, current_worker_by_year, current_worker_by_unity, year)
    SynchronizationConfigs.dependencies_by_klass(worker_name).select do |klass|
      config = SynchronizationConfigs.find(klass)
      by_year = config[:by_year] && current_worker_by_year
      by_unity = config[:by_unity] && current_worker_by_unity

      worker_completed?(klass, by_year, by_unity, year)
    end.size
  end

  def worker_completed?(worker_name, by_year, by_unity, year)
    worker_states = initialized_worker_states_by(worker_name, by_year, by_unity, year)

    worker_states.by_status(ApiSynchronizationStatus::COMPLETED).exists?
  end

  def worker_initialized?(worker_name, by_year, by_unity, year)
    initialized_worker_states_by(worker_name, by_year, by_unity, year).exists?
  end

  def initialized_worker_states_by(worker_name, by_year, by_unity, year)
    worker_states = WorkerState.by_worker_batch_id(worker_batch.id)
                               .by_kind(worker_name)
    worker_states = worker_states.by_meta_data(:year, year) if by_year && year.present?

    if by_unity && params[:unity_api_code].present?
      worker_states = worker_states.by_meta_data(:unity_api_code, params[:unity_api_code])
    end

    worker_states
  end

  def enqueue_job(synchronizer, year)
    SynchronizerBuilder.enqueue(
      params.slice(
        :entity_id,
        :current_years,
        :synchronization
      ).merge(
        klass: synchronizer[:klass],
        worker_batch_id: worker_batch.id,
        years: year.to_s.split(','),
        unities_api_code: params[:unity_api_code].to_s.split(','),
        filtered_by_year: synchronizer[:by_year],
        filtered_by_unity: synchronizer[:by_unity]
      )
    )
  end
end
