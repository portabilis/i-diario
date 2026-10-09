VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { 
    # Sem gravação: requisição sem interação no cassete falha em vez de ir para a rede e sujar a árvore.
    # Para gravar um cassete novo, passe record: :once no use_cassette e remova a opção antes do commit.
    :record => :none,
    :match_requests_on => [:method, VCR.request_matchers.uri_without_param(:modified)]
  }
  c.allow_http_connections_when_no_cassette = false
end
