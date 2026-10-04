# A transação dos fixtures do Rails 5.0 só alcança as conexões dos pools que já existem quando o
# exemplo começa (ActiveRecord::TestFixtures#setup_fixtures chama enlist_fixture_connections, que lê
# connection_pool_list). O pool de cada Entity nasce no primeiro using_connection do processo: sem
# criá-lo antes do enlist, o exemplo que o cria grava fora da transação e o registro fica no banco
# até o fim da execução. Os fixtures globais já estão carregados neste ponto, então Entity enxerga
# as entidades de teste e o checkout da conexão é o que materializa o pool no connection handler.
module TenantFixtureConnections
  def enlist_fixture_connections
    Entity.find_each { |entity| entity.using_connection { ActiveRecord::Base.connection } }

    super
  end
end

RSpec.configure do |config|
  config.include TenantFixtureConnections
end
