# Reseta o contexto thread-local (tenant, usuário e origem) ao fim de cada
# job. Workers Sidekiq são multi-thread e reusam threads de vida longa entre
# jobs; sem este reset, um job pode herdar o Entity.current/User.current
# definido por outro job na mesma thread (vazamento cross-tenant).
class ThreadContextResetMiddleware
  def call(_worker, _job, _queue)
    yield
  ensure
    Entity.current = nil
    User.current = nil
    Thread.current[:origin_type] = nil
  end

  # Extraído para um método único (em vez de inline no bloco
  # configure_server) para permitir testar o registro na chain.
  def self.register(chain)
    chain.add self
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware { |chain| ThreadContextResetMiddleware.register(chain) }
end
