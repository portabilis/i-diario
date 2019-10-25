class SynchronizationConfigs
  ALL = YAML.safe_load(
    File.open(Rails.root.join('config', 'synchronization_configs.yml'))
  ).with_indifferent_access[:synchronizers]
  KLASSES = ALL.map { |config| config[:klass] }

  class << self
    def find(klass)
      ALL.find { |config| config[:klass] == klass }
    end

    def dependents_by_klass(klass)
      find(klass)[:dependents] || []
    end

    def dependencies_by_klass(klass)
      find(klass)[:dependencies] || []
    end

    def without_dependencies
      ALL.select { |config| config[:dependencies].blank? }
    end
  end
end
