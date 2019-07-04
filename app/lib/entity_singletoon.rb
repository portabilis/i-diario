require 'thread_parent'

module EntitySingletoon
  extend self

  def set entity
    Thread.current[:entity] = entity
  end

  def current
    entity_thread_or_parentest[:entity]
  end

  def with entity, &block
    thread = Thread.current

    prev_entity = thread[:entity]
    begin
      thread[:entity] = entity
  
      entity.using_connection &block
    ensure
      thread[:entity] = prev_entity
    end

  end
  
  def entity_thread_or_parentest
    thread = Thread.current

    while not thread.key?(:entity) and thread.parent
      thread = thread.parent
    end

    thread
  end

  def current_domain
    raise Exception.new("Entity not found") if self.current.blank?

    self.current.domain
  end
end