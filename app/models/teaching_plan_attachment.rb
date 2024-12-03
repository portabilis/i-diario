class TeachingPlanAttachment < ApplicationRecord
  audited associated_with: :teaching_plan, except:
  [:attachment_updated_at, :attachment_file_name_with_hash, :attachment, :teaching_plan_id]

  belongs_to :teaching_plan

  mount_uploader :attachment, DocUploader

  delegate :filename, to: :attachment

  validate :attachment_extension_whitelist

  before_save :set_attachment_attributes

  private

  def attachment_extension_whitelist
    return unless attachment.present? && !attachment.file.extension.match(/\A(jpeg|jpg|png|gif|pdf|odt|doc|docx|ods|xls|xlsx|odp|ppt|pptx|odg|xml|csv)\z/i)

    errors.add(:attachment, "Somente arquivos nos formatos JPEG, JPG, PNG, GIF, PDF, ODT, DOC, DOCX, ODS, XLS, XLSX, ODP, PPT, PPTX, ODG, XML, or CSV file")
  end

  def set_attachment_attributes
    return unless attachment.present? && attachment.file.present?

    self.attachment_file_name = attachment.file.filename
    self.attachment_content_type = attachment.file.content_type
    self.attachment_file_size = "#{attachment.file.size} kB"
  end
end
