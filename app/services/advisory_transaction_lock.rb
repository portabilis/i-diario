# Serializa por chave as escritas que o índice único do banco só rejeita depois do fato: quem chega
# depois espera a transação de quem chegou antes terminar e encontra o registro pronto, em vez de
# perder o INSERT e ter a transação desfeita.
#
# A transação é aberta aqui porque `pg_advisory_xact_lock` só libera no COMMIT/ROLLBACK — fora de uma
# transação o lock seria liberado no mesmo statement e não protegeria nada. `requires_new` garante um
# savepoint próprio quando o chamador já tem transação aberta: sem ele, o INSERT que falha aborta a
# transação externa e a tentativa seguinte morre em `PG::InFailedSqlTransaction`, escondendo o erro
# real. `SET LOCAL lock_timeout` limita a espera: sem ele um detentor lento prende requisição,
# thread e conexão do pool por tempo indefinido.
#
# Rails 5.0 não tem `ActiveRecord::Deadlocked` nem `ActiveRecord::LockWaitTimeout` (chegaram no 5.1):
# deadlock e timeout chegam como `ActiveRecord::StatementInvalid` e só o `cause` diz qual erro do
# PostgreSQL ocorreu.
#
# O advisory lock é escopado por banco e cada Entity tem o seu, então redes distintas não disputam a
# mesma chave. A chave é reduzida a int4 por `hashtext`: colisão faz dois fluxos independentes se
# esperarem, nunca corrompe dado.
class AdvisoryTransactionLock
  MAX_ATTEMPTS = 3
  LOCK_TIMEOUT_MS = 5_000

  # A mensagem é constante e a chave vai só para o log: o Honeybadger agrupa por classe e mensagem, e
  # a chave carrega turma e data — interpolada, geraria um fault distinto por turma por dia.
  WAIT_TIMEOUT_MESSAGE = 'espera pelo advisory lock excedeu o limite'.freeze

  WaitTimeout = Class.new(StandardError)

  def self.call(key, &block)
    new(key).call(&block)
  end

  def initialize(key)
    @key = key.to_s
  end

  def call
    attempt = 1

    begin
      ActiveRecord::Base.transaction(requires_new: true) do
        acquire
        yield
      end
    rescue ActiveRecord::StatementInvalid => error
      raise wait_timeout(error) if wait_timeout?(error)
      raise unless concurrent_write?(error)
      raise exhausted(error, attempt) if attempt >= MAX_ATTEMPTS

      Rails.logger.warn(
        "[#{self.class}] tentativa #{attempt} perdeu a corrida e será refeita (chave: #{key})"
      )
      attempt += 1
      retry
    end
  end

  private

  attr_reader :key

  def acquire
    connection = ActiveRecord::Base.connection
    connection.execute("SET LOCAL lock_timeout = #{LOCK_TIMEOUT_MS}")
    connection.execute("SELECT pg_advisory_xact_lock(hashtext(#{connection.quote(key)}))")
  end

  # Corrida legítima entre dois escritores: refazer o bloco com o lock em mãos converge. Deadlock
  # entra aqui porque a transação segura linhas de outras tabelas pelos callbacks dos models, e outro
  # fluxo pode tocá-las em ordem diferente.
  def concurrent_write?(error)
    error.is_a?(ActiveRecord::RecordNotUnique) || error.cause.is_a?(PG::TRDeadlockDetected)
  end

  def wait_timeout?(error)
    error.cause.is_a?(PG::LockNotAvailable)
  end

  def wait_timeout(error)
    Rails.logger.error(
      "[#{self.class}] #{WAIT_TIMEOUT_MESSAGE} de #{LOCK_TIMEOUT_MS}ms (chave: #{key}): #{error.message}"
    )

    WaitTimeout.new(WAIT_TIMEOUT_MESSAGE)
  end

  # Violação que não converge não é corrida: sem teto viraria laço quente segurando thread e conexão,
  # sem nada no Honeybadger. Re-levantar entrega o erro original com o índice e a chave em conflito.
  def exhausted(error, attempt)
    Rails.logger.error(
      "[#{self.class}] escrita concorrente não convergiu após #{attempt} tentativas " \
      "(chave: #{key}): #{error.message}"
    )

    error
  end
end
