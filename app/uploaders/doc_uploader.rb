class DocUploader < CarrierWave::Uploader::Base
  def store_dir
    "#{Rails.env}/#{model.class.to_s.underscore.pluralize}/#{model.id}"
  end

  def extension_whitelist
    %w[png jpeg jpg gif pdf odt doc docx ods xls xlsx odp ppt pptx odg xml csv]
  end

  def filename
    path&.split('/')&.last
  end

  def aws_bucket
    Rails.application.secrets[:DOC_UPLOADER_AWS_BUCKET] || Rails.application.secrets[:AWS_BUCKET]
  end

  def aws_credentials
    {
      access_key_id:     Rails.application.secrets['AWS_ACCESS_KEY_ID'],
      secret_access_key: Rails.application.secrets['AWS_SECRET_ACCESS_KEY'],
      region:            Rails.application.secrets['DOC_UPLOADER_AWS_REGION'],
      stub_responses:    Rails.env.test?
    }
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
