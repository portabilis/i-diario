module EntityWorker
  def perform entity_id, *args
    entity = Entity.find(entity_id)

    EntitySingletoon.with(entity) do
      perform_in_entity *args
    end
  end

  def perform_in_entity *args
    raise NotImplementedError.new("You should implement perform_in_entity method")
  end

  module ClassMethods
    def perform_current_entity *args
      perform_async EntitySingletoon.current.id, *args
    end
  end

  def self.included base
    base.extend ClassMethods
  end
end
