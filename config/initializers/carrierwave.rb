FOG_AUTHENTICATED_URL_EXPIRATION = 14_400 # 4 hours

CarrierWave.configure do |config|
  if Rails.application.secrets['AWS_ACCESS_KEY_ID'] && !Rails.env.development?
    config.storage = :aws
    config.aws_bucket = Rails.application.secrets[:AWS_BUCKET]
    config.aws_acl = 'private'
    config.aws_authenticated_url_expiration = FOG_AUTHENTICATED_URL_EXPIRATION
    config.aws_credentials = {
      access_key_id:     Rails.application.secrets['AWS_ACCESS_KEY_ID'],
      secret_access_key: Rails.application.secrets['AWS_SECRET_ACCESS_KEY'],
      region:            Rails.application.secrets['AWS_REGION'],
      stub_responses:    Rails.env.test?
    }
  else
    config.storage = :file
  end
end
