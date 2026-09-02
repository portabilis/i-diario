# Lock consultivo transacional do PostgreSQL (pg_advisory_xact_lock): quem chamar com a mesma chave
# espera a transação de quem chegou antes terminar. O lock é liberado no COMMIT/ROLLBACK, por isso
# exige transação aberta — fora dela seria liberado na hora e não protegeria nada.
# A chave é reduzida a int4 por hashtext: colisão só faz dois fluxos independentes se esperarem.
class AdvisoryTransactionLock
  def self.call(key)
    connection = ActiveRecord::Base.connection

    raise ArgumentError, "#{name} exige transação aberta (chave: #{key})" unless connection.transaction_open?

    connection.execute("SELECT pg_advisory_xact_lock(hashtext(#{connection.quote(key.to_s)}))")
  end
end
