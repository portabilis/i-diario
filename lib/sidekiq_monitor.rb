class SidekiqMonitor
  SIDEKIQ_FILES = Dir["#{Rails.root}/config/sidekiq_*.yml"]
  QUEUES = SIDEKIQ_FILES.map do |file|
    YAML.load(File.open(file))[:tag]
  end

  class << self
    def processses_running?
      QUEUES.none? { |queue| find_processes(queue).blank? }
    end

    private

    def find_processes(queue)
      `ps aux | grep sidekiq | grep #{queue} | grep -v grep`.split(/\n/)
    end
  end
end
