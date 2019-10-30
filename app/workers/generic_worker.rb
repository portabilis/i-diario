class GenericWorker
  include Sidekiq::Worker

  def perform(entity_name, klass, id, block)
    Entity.find_by_name(entity_name).using_connection do
      obj = klass.constantize.find(id)
      klass.constantize.class_eval(block).call(obj)
    end
  end
end
