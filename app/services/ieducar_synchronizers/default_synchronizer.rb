class DefaultSynchronizer
  def self.synchronize!(params)
    new(params).synchronize
  end

  def initialize(params)
    @entity_id = params[:entity_id]
    @last_two_years = params[:last_two_years]
    @synchronization = params[:synchronization]
    @worker_batch = params[:worker_batch]
  end

  def synchronize
    @synchronization.worker_batch.update(total_workers: total_synchronizers(@synchronization.full_synchronization))

    SynchronizationConfigs.without_dependencies.each do |synchronizer|
      SynchronizerBuilderWorker.perform_async(
        klass: synchronizer[:klass],
        synchronization_id: @synchronization.id,
        worker_batch_id: @worker_batch.id,
        entity_id: @entity_id,
        years: years_to_synchronize(@last_two_years),
        unities_api_code: unities_api_code,
        filtered_by_year: synchronizer[:by_year],
        filtered_by_unity: synchronizer[:by_unity]
      )
    end
  end

  def unities_api_code
    @unities_api_code ||= Unity.with_api_code.pluck(:api_code)
  end

  def years_to_synchronize(last_two_years = false)
    @years_to_synchronize ||= begin
      years = Unity.with_api_code
                   .joins(:school_calendars)
                   .pluck('school_calendars.year')
                   .uniq
                   .compact
                   .sort
                   .reverse

      years = years.take(2) if last_two_years

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
    )
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
end
