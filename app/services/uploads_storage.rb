class UploadsStorage
  def self.s3?
    (Rails.application.secrets[:AWS_ACCESS_KEY_ID]).present? &&
      (Rails.application.secrets[:AWS_SECRET_ACCESS_KEY]).present? &&
      (Rails.application.secrets[:DOC_UPLOADER_AWS_REGION] ||
        Rails.application.secrets[:AWS_REGION]).present? &&
      (Rails.application.secrets[:DOC_UPLOADER_AWS_BUCKET] ||
        Rails.application.secrets[:AWS_BUCKET]).present?
  end

  def self.local?
    !s3?
  end
end
