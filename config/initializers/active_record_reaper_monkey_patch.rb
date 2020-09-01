# TODO Remover esse arquivo depois de atualizar para Rails >=5.2
#
# Esses monkeypatches foram feitos para diminuir o número de conexões simultaneas no banco de dados.
#
# [1] Ao inicializar o ActiveRecord irá limpar as conexões com o banco de dados, para evitar que fique conexões
# zumbis.
#
# [2] Junto do reaper do ActiveRecord, irá limpar conexões idle (flush)

# [1] https://github.com/rails/rails/pull/28057
class ActiveRecord::Railtie
  initializer "active_record.clear_active_connections" do
    config.after_initialize do
      ActiveSupport.on_load(:active_record) do
        clear_active_connections!
      end
    end
  end
end

# [2] https://github.com/rails/rails/pull/31221
class ActiveRecord::ConnectionAdapters::ConnectionPool
  def initialize(spec)
    super()

    @spec = spec

    @checkout_timeout = (spec.config[:checkout_timeout] && spec.config[:checkout_timeout].to_f) || 5
    if @idle_timeout = spec.config.fetch(:idle_timeout, 60)
      @idle_timeout = @idle_timeout.to_f
      @idle_timeout = nil if @idle_timeout <= 0
    end

    # +reaping_frequency+ is configurable mostly for historical reasons, but it could
    # also be useful if someone wants a very low +idle_timeout+.
    reaping_frequency = spec.config.fetch(:reaping_frequency, 60)
    @reaper = Reaper.new(self, reaping_frequency)
    @reaper.run

    # default max pool size to 5
    @size = (spec.config[:pool] && spec.config[:pool].to_i) || 5

    # The cache of reserved connections mapped to threads
    @reserved_connections = ThreadSafe::Cache.new(:initial_capacity => @size)

    @connections         = []
    @automatic_reconnect = true

    @available = Queue.new self
  end

  # Disconnect all connections that have been idle for at least
  # +minimum_idle+ seconds. Connections currently checked out, or that were
  # checked in less than +minimum_idle+ seconds ago, are unaffected.
  def flush(minimum_idle = @idle_timeout)
    return if minimum_idle.nil?

    idle_connections = synchronize do
      @connections.select do |conn|
        !conn.in_use? && conn.seconds_idle >= minimum_idle
      end.each do |conn|
        conn.lease

        @available.delete conn
        @connections.delete conn
      end
    end

    idle_connections.each do |conn|
      conn.disconnect!
    end
  end

  # Disconnect all currently idle connections. Connections currently checked
  # out are unaffected.
  def flush!
    reap
    flush(-1)
  end
end

class ActiveRecord::ConnectionAdapters::ConnectionHandler
  # Disconnects all currently idle connections.
  #
  # See ConnectionPool#flush! for details.
  def flush_idle_connections!
    connection_pool_list.each(&:flush!)
  end
end

class ActiveRecord::ConnectionAdapters::ConnectionPool::Reaper
  def run
    return unless frequency && frequency > 0
    Thread.new(frequency, pool) { |t, p|
      while true
        sleep t
        p.reap
        p.flush
      end
    }
  end
end

class ActiveRecord::ConnectionAdapters::AbstractAdapter
  def initialize(connection, logger = nil, pool = nil) #:nodoc:
    super()

    @connection          = connection
    @owner               = nil
    @instrumenter        = ActiveSupport::Notifications.instrumenter
    @logger              = logger
    @pool                = pool
    @idle_since          = Concurrent.monotonic_time
    @schema_cache        = ActiveRecord::ConnectionAdapters::SchemaCache.new self
    @visitor             = nil
    @prepared_statements = false
  end

  def expire
    @idle_since = Concurrent.monotonic_time
    @owner = nil
  end

  # Seconds since this connection was returned to the pool
  def seconds_idle # :nodoc:
    return 0 if in_use?
    Concurrent.monotonic_time - @idle_since
  end
end
