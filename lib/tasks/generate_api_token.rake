desc 'Creates new API token for the given entity name'
task :generate_api_token, [:name] => [:environment] do |_t, args|
  entity = Entity.find_by(name: args.name)

  raise "Unable to find entity '#{args.name}'" unless entity

  token = SecureRandom.hex(15)

  entity.using_connection do
    api_config = IeducarApiConfiguration.current
    api_config.update(api_security_token: token)
  end
end
