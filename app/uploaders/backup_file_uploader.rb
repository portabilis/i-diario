# encoding: utf-8

class BackupFileUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/#{Rails.env}/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
