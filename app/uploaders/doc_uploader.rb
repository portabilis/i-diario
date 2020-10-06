class DocUploader < CarrierWave::Uploader::Base
  def store_dir
    "#{Rails.env}/#{model.class.to_s.underscore}/#{model.id}"
  end

  def extension_white_list
    %w[png jpeg jpg gif pdf odt doc docx ods xls xlsx odp ppt pptx odg xml csv]
  end

  def filename
    original = original_filename.split(".")[0..-2].join(".")
    "#{original} - #{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end

  def fog_directory
    Rails.application.secrets[:BUCKET_NAME]
  end
end
