class DefaultSynchronizer
  DEFAULT_SYNCHRONIZER_COUNT = 1

  def self.synchronize!(params)
    new(params).synchronize
  end

  def initialize(params)
    @entity_id = params[:entity_id]
    @current_years = params[:current_years]
    @synchronization = params[:synchronization]
    @worker_batch = params[:worker_batch]
  end

  def synchronize
    @worker_batch.update(
      total_workers: total_synchronizers(@synchronization.full_synchronization) + DEFAULT_SYNCHRONIZER_COUNT
    )

    SynchronizationConfigs.without_dependencies.each do |synchronizer|
      SynchronizerBuilderWorker.perform_async(
        klass: synchronizer[:klass],
        synchronization_id: @synchronization.id,
        worker_batch_id: @worker_batch.id,
        entity_id: @entity_id,
        years: years_to_synchronize,
        unities_api_code: unities_api_code,
        filtered_by_year: synchronizer[:by_year],
        filtered_by_unity: synchronizer[:by_unity],
        current_years: @current_years
      )
    end

    worker_state = WorkerState.find_by(
      worker_batch_id: @worker_batch.id,
      kind: DefaultSynchronizer.to_s
    )

    @worker_batch.increment
    worker_state.end!
  end

  private

  attr_accessor :current_years

  def unities_api_code
    @unities_api_code ||= Unity.with_api_code.pluck(:api_code).uniq
  end

  def years_to_synchronize
    @years_to_synchronize ||= begin
      years = Unity.with_api_code
                   .joins(:school_calendars)
                   .pluck('school_calendars.year')
                   .uniq
                   .compact
                   .sort
                   .reverse

      years = slice_years(years) if current_years

      years
    end
  end

  def total_synchronizers(full_synchronization)
    return total_synchronizers_with_full_synchronization if full_synchronization

    total_synchronizers_with_simple_synchronization
  end

  def total_synchronizers_with_full_synchronization
    (
      (synchronizers_by_year_and_unity.size * years_to_synchronize.size * unities_api_code.size) +
      (synchronizers_by_year_to_full_synchronization.size * years_to_synchronize.size) +
      (synchronizers_by_unity.size * unities_api_code.size) +
      single_synchronizers.size
    )
  end

  def total_synchronizers_with_simple_synchronization
    (
      (synchronizers_by_year_and_unity.size * years_to_synchronize.size) +
      (synchronizers_by_year.size * years_to_synchronize.size) +
      (unities_api_code.present? ? synchronizers_by_unity.size : 0) +
      single_synchronizers.size
    ) + school_calendars_simple_synchronization_count
  end

  def single_synchronizers
    @single_synchronizers ||= SynchronizationConfigs::ALL.select { |synchronizer|
      !synchronizer[:by_year] && !synchronizer[:by_unity]
    }
  end

  def synchronizers_by_year
    @synchronizers_by_year ||= SynchronizationConfigs::ALL.select { |synchronizer|
      synchronizer[:by_year] && !synchronizer[:by_unity]
    }
  end

  def synchronizers_by_year_to_full_synchronization
    @synchronizers_by_year_to_full_synchronization ||= SynchronizationConfigs::ALL.select { |synchronizer|
      synchronizer[:by_year] && !synchronizer[:by_unity] && !synchronizer[:only_simple_synchronization]
    }
  end

  def synchronizers_by_unity
    @synchronizers_by_unity ||= SynchronizationConfigs::ALL.select { |synchronizer|
      !synchronizer[:by_year] && synchronizer[:by_unity]
    }
  end

  def synchronizers_by_year_and_unity
    @synchronizers_by_year_and_unity ||= SynchronizationConfigs::ALL.select { |synchronizer|
      synchronizer[:by_year] && synchronizer[:by_unity]
    }
  end

  def school_calendars_simple_synchronization_count
    unities_api_code.size - 1
  end

  def slice_years(years)
    if Date.current.month <= 3 || years.include?(Date.current.year + 1) || @synchronization.full_synchronization
      years.take(2)
    else
      years.take(1)
    end
  end
end
