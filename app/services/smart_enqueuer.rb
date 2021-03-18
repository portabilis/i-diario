class SmartEnqueuer
  def initialize(queues)
    @queues = queues
  end

  def less_used_queue
    return @queues.first if @queues.size == 1

    @queues.min_by { |queue| Sidekiq::Queue.new(queue).size }
  end
end
