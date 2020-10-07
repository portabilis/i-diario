class DocUploader < CarrierWave::Uploader::Base
  FOG_CONFIG =
    begin
      config_file =
        if File.exist? Rails.root.join('config', "doc_uploader_fog_#{Rails.env}.yml")
          Rails.root.join('config', "doc_uploader_fog_#{Rails.env}.yml")
        elsif File.exist? Rails.root.join('config', "fog_#{Rails.env}.yml")
          Rails.root.join('config', "fog_#{Rails.env}.yml")
        else
          Rails.root.join('config', 'fog.yml')
        end

      YAML.safe_load(
        File.open(config_file)
      ).with_indifferent_access
    end

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

  def fog_directory
    Rails.application.secrets[:DOC_UPLOADER_FOG_DIRECTORY] || Rails.application.secrets[:FOG_DIRECTORY]
  end

  def fog_credentials
    FOG_CONFIG
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
