# encoding: utf-8
class UserProfilePictureUploader < CarrierWave::Uploader::Base
  def store_dir
    "uploads/#{model.class.to_s.underscore.pluralize}/#{mounted_as}/entity-#{Entity.current.id}/#{model.id}"
  end

  def extension_whitelist
    %w(jpg jpeg gif png)
  end
end
