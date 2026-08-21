# Zera o contexto thread-local (tenant, usuário e origem) antes e depois de
# cada job. Workers Sidekiq são multi-thread e reusam threads de vida longa
# entre jobs; este reset garante que nenhum job enxergue contexto deixado por
# outro job (ou pelo boot) na mesma thread.
#
# Defesa em profundidade: todos os workers atuais passam por
# Entity#using_connection (que restaura Entity.current em ensure) e nenhum
# seta User.current/origin_type — mas nada impede código novo de setar o
# contexto diretamente, e este middleware fecha esse vetor.
class ThreadContextResetMiddleware
  def call(_worker, _job, _queue)
    reset_context

    yield
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
