class TeachingPlanAttachment < ApplicationRecord
  belongs_to :teaching_plan

  mount_uploader :attachment, DocUploader

  delegate :filename, to: :attachment

  validate :attachment_extension_whitelist

  private

  def attachment_extension_whitelist
    if attachment.present? && !attachment.file.extension.match(/\A(doc|docx|pdf|txt)\z/)
      errors.add(:attachment, "must be a JPEG, JPG, PNG, GIF, PDF, ODT, DOC, DOCX, ODS, XLS, XLSX, ODP, PPT, PPTX, ODG, XML, or CSV file")
    end
  end
end
