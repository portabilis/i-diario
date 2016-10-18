# encoding: utf-8
class ReportUploader < CarrierWave::Uploader::Base
  def store_dir
    "uploads/entity-#{model.entity_id}/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
