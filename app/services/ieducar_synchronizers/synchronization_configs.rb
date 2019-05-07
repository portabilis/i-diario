class SynchronizationConfigs
  SYNCHRONIZERS = YAML.safe_load(
    File.open(Rails.root.join('config', 'synchronization_configs.yml'))
  ).with_indifferent_access[:synchronizers]
  KLASSES = SYNCHRONIZERS.map { |synchronizer| synchronizer[:klass] }

  class << self
    def configs(klass)
      SYNCHRONIZERS.find { |configs| configs[:klass] == klass }
    end

    def config(klass, kind)
      configs(klass)[kind]
    end

    def dependents(klass)
      SYNCHRONIZERS.find { |configs| configs[:klass] == klass }[:dependents] || []
    end

    def dependencies(klass)
      SYNCHRONIZERS.find { |configs| configs[:klass] == klass }[:dependencies] || []
    end

    def synchronizers_without_dependencies
      SYNCHRONIZERS.select { |synchronizer| synchronizer[:dependencies].blank? }
    end
  end
end
