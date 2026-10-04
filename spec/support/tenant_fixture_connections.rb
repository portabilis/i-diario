# A transação dos fixtures do Rails 5.0 só alcança as conexões dos pools que já existem quando o
# exemplo começa (ActiveRecord::TestFixtures#setup_fixtures chama enlist_fixture_connections, que lê
# connection_pool_list). O pool de cada Entity nasce no primeiro using_connection do processo: sem
# criá-lo antes do enlist, o exemplo que o cria grava fora da transação e o registro fica no banco
# até o fim da execução. Os fixtures globais já estão carregados neste ponto, então Entity enxerga
# as entidades de teste e o checkout da conexão é o que materializa o pool no connection handler.
#
# Entity criada durante o exemplo escapa dessa lista: o pool dela nasce depois do enlist. Para esse
# caso o arquivo instrumenta ConnectionHandler#establish_connection com o evento
# `!connection.active_record` e assina o evento enquanto o exemplo roda, entrando com a conexão nova
# na mesma transação. É o comportamento que o Rails 5.1 tem nativamente, transcrito aqui para poder
# ser removido na subida de versão.
module TenantFixtureConnections
  CONNECTION_POOL_EVENT = '!connection.active_record'.freeze

  # Com o pool registrado, o evento `!connection.active_record` avisa quem estiver assinando; é o
  # gancho que o Rails 5.1 usa para incluir na transação a conexão criada no meio do exemplo.
  module ConnectionPoolInstrumentation
    def establish_connection(spec)
      ActiveSupport::Notifications.instrument(CONNECTION_POOL_EVENT, spec_name: spec.name) { super }
    end
  end

  def enlist_fixture_connections
    Entity.find_each { |entity| entity.using_connection { ActiveRecord::Base.connection } }

    super
  end

  def setup_fixtures(config = ActiveRecord::Base)
    super

    return unless run_in_transaction?

    @tenant_pool_subscriber = ActiveSupport::Notifications.subscribe(CONNECTION_POOL_EVENT) do |_, _, _, _, payload|
      enlist_new_pool_connection(payload[:spec_name])
    end
  end

  def teardown_fixtures
    if @tenant_pool_subscriber
      ActiveSupport::Notifications.unsubscribe(@tenant_pool_subscriber)
      @tenant_pool_subscriber = nil
    end

    super
  end

  private

  # A conexão já entra na transação na primeira vez que o pool é usado, ainda antes do primeiro
  # write: sem isso ela abriria a própria transação (ou comitaria solta) fora da do exemplo.
  def enlist_new_pool_connection(spec_name)
    connection = ActiveRecord::Base.connection_handler.retrieve_connection(spec_name)
    return if @fixture_connections.include?(connection)

    connection.begin_transaction(joinable: false)
    @fixture_connections << connection
  end
end

ActiveRecord::ConnectionAdapters::ConnectionHandler.prepend(TenantFixtureConnections::ConnectionPoolInstrumentation)

RSpec.configure do |config|
  config.include TenantFixtureConnections
end
