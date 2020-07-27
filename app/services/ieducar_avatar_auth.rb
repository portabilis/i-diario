class IeducarAvatarAuth
  CREDENTIALS = Aws::Credentials.new(Rails.application.secrets.ieducar_aws_access_key_id.to_s,
                                     Rails.application.secrets.ieducar_aws_secret_access_key.to_s)

  def initialize(url)
    @url = url
  end

  def generate_new_url
    Rails.cache.fetch(['IeducarAvatarAuth#generate_new_url', @url],
                      expires_in: FOG_AUTHENTICATED_URL_EXPIRATION.seconds) do
      return @url unless @url.include? 's3.amazonaws.com'

      uri = URI(@url)

      bucket_name = uri.host.split('.').first
      path = uri.path[1..-1]

      bucket = resource.bucket(bucket_name)

      obj = bucket.object(path)
      obj.presigned_url(:get, expires_in: FOG_AUTHENTICATED_URL_EXPIRATION)
    end
  rescue StandardError => error
    Honeybadger.notify(error)

    @url
  end

  private

  def client
    @client ||= Aws::S3::Client.new(region: Rails.application.secrets.ieducar_aws_default_region,
                                    credentials: CREDENTIALS)
  end

  def resource
    @resource ||= Aws::S3::Resource.new(client: client)
  end
end
