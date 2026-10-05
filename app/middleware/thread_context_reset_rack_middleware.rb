# Zera o contexto thread-local (tenant, usuário e origem) ao fim de cada
# request. Threads do Puma são reusadas entre requests; sem este reset, uma
# request pode herdar o contexto da anterior na mesma thread.
#
# O handle_customer já restaura Entity.current na sua própria fronteira, mas
# só vale para quem passa por ele: um controller com
# `skip_around_action :handle_customer` que chame current_entity (que seta
# Entity.current como efeito colateral) deixaria o tenant retido na thread.
# Como middleware Rack, este reset independe de quais around_actions rodaram.
#
# Contraparte web do ThreadContextResetMiddleware (Sidekiq).
class ThreadContextResetRackMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    reset_context

    @app.call(env)
  ensure
    reset_context
  end

  private

  def reset_context
    Entity.current = nil
    User.current = nil
    Thread.current[:origin_type] = nil
  end
end
