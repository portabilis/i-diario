VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { 
    :record => :new_episodes,
    :match_requests_on => [:method, VCR.request_matchers.uri_without_param(:modified)]
  }
  c.allow_http_connections_when_no_cassette = false
end
