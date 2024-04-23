class AwsS3HandlerService
  def initialize
    aws_access_key_id = Rails.application.secrets[:AWS_ACCESS_KEY_ID]
    aws_secret_access_key = Rails.application.secrets[:AWS_SECRET_ACCESS_KEY]
    aws_region = Rails.application.secrets[:DOC_UPLOADER_AWS_REGION] || Rails.application.secrets[:AWS_REGION]

    aws_credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)

    @bucket_name = Rails.application.secrets[:DOC_UPLOADER_AWS_BUCKET] || Rails.application.secrets[:AWS_BUCKET]
    @s3_client = Aws::S3::Client.new(region: aws_region, credentials: aws_credentials)
  end

  def copy_object(source, target, object)
    begin
      @s3_client.copy_object(bucket: @bucket_name, copy_source: "/#{@bucket_name}/#{uri_escape(source)}", key: target)
    rescue Aws::S3::Errors::NoSuchKey
      false
    rescue Exception => error
      Honeybadger.context(object_name: object.class, object_id: object.id, source: uri_escape(source), target: target)
      Honeybadger.notify(error)
      raise
    end
  end

  def uri_escape(string)
    CGI.escape(string.encode('UTF-8')).gsub('+', '%20').gsub('%7E', '~')
  end
end
