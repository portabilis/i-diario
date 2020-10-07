FOG_AUTHENTICATED_URL_EXPIRATION = 14_400 # 4 hours

if defined?(Fog)
  config_file =
    if File.exist? Rails.root.join('config', "fog_#{Rails.env}.yml")
      Rails.root.join('config', "fog_#{Rails.env}.yml")
    else
      Rails.root.join('config', 'fog.yml')
    end

  fog_config = YAML.safe_load(
    File.open(config_file)
  ).with_indifferent_access

  CarrierWave.configure do |config|
    config.fog_credentials = fog_config
    Rails.logger.info fog_config.inspect
    config.storage = :fog
    config.fog_public = false
    config.fog_authenticated_url_expiration = FOG_AUTHENTICATED_URL_EXPIRATION
    config.fog_directory = Rails.application.secrets[:FOG_DIRECTORY]
  end
end
