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
        flush_idle_connections!
      end
    end
  end
end

module ActiveRecord::ConnectionHandling
  delegate :clear_active_connections!, :clear_reloadable_connections!,
           :clear_all_connections!, :flush_idle_connections!, to: :connection_handler
end

# [2] https://github.com/rails/rails/pull/31221
class ActiveRecord::ConnectionAdapters::ConnectionPool
  def initialize(spec)
    super()
    @spec = spec

    @checkout_timeout = (spec.config[:checkout_timeout] && spec.config[:checkout_timeout].to_f) || 5
    if @idle_timeout = spec.config.fetch(:idle_timeout, 300)
      @idle_timeout = @idle_timeout.to_f
      @idle_timeout = nil if @idle_timeout <= 0
    end

    # default max pool size to 5
    @size = (spec.config[:pool] && spec.config[:pool].to_i) || 5
    # This variable tracks the cache of threads mapped to reserved connections, with the
    # sole purpose of speeding up the +connection+ method. It is not the authoritative
    # registry of which thread owns which connection. Connection ownership is tracked by
    # the +connection.owner+ attr on each +connection+ instance.
    # The invariant works like this: if there is mapping of <tt>thread => conn</tt>,
    # then that +thread+ does indeed own that +conn+. However, an absence of a such
    # mapping does not mean that the +thread+ doesn't own the said connection. In
    # that case +conn.owner+ attr should be consulted.
    # Access and modification of <tt>@thread_cached_conns</tt> does not require
    # synchronization.
    @thread_cached_conns = Concurrent::Map.new(initial_capacity: @size)
    @connections         = []
    @automatic_reconnect = true
    # Connection pool allows for concurrent (outside the main +synchronize+ section)
    # establishment of new connections. This variable tracks the number of threads
    # currently in the process of independently establishing connections to the DB.
    @now_connecting = 0
    @threads_blocking_new_connections = 0
    @available = ConnectionLeasingQueue.new self

    @lock_thread = false

    # +reaping_frequency+ is configurable mostly for historical reasons, but it could
    # also be useful if someone wants a very low +idle_timeout+.
    reaping_frequency = spec.config.fetch(:reaping_frequency, 60)
    @reaper = Reaper.new(self, reaping_frequency && reaping_frequency.to_f)
    @reaper.run
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
      loop do
        sleep t
        p.reap
        p.flush
      end
    }
  end
end

class ActiveRecord::ConnectionAdapters::AbstractAdapter
  def initialize(connection, logger = nil, config = {}) # :nodoc:
    super()
    @connection          = connection
    @owner               = nil
    @instrumenter        = ActiveSupport::Notifications.instrumenter
    @logger              = logger
    @config              = config
    @pool                = nil
    @idle_since          = Concurrent.monotonic_time
    @schema_cache        = ActiveRecord::ConnectionAdapters::SchemaCache.new self
    @quoted_column_names, @quoted_table_names = {}, {}
    @visitor = arel_visitor

    if self.class.type_cast_config_to_boolean(config.fetch(:prepared_statements) { true })
      @prepared_statements = true
      @visitor.extend(ActiveRecord::ConnectionAdapters::DetermineIfPreparableVisitor)
    else
      @prepared_statements = false
    end
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