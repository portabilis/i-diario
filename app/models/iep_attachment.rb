class IepAttachment < ApplicationRecord
  audited associated_with: :iep,
          except: [:attachment_updated_at, :attachment, :individualized_educational_plan_id]

  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id

  mount_uploader :attachment, DocUploader

  delegate :filename, to: :attachment

  validate :attachment_extension_whitelist

  before_save :set_attachment_attributes
  before_destroy :prevent_destroy_if_versioned   # imutabilidade do laudo em versão publicada

  private

  def attachment_extension_whitelist
    return unless attachment.present? && !attachment.file.extension.match(/\A(jpeg|jpg|png|gif|pdf|odt|doc|docx|ods|xls|xlsx|odp|ppt|pptx|odg|xml|csv)\z/i)

    errors.add(:attachment, I18n.t('activerecord.errors.models.iep_attachment.attributes.attachment.invalid_extension'))
  end

  def set_attachment_attributes
    return unless attachment.present? && attachment.file.present?

    self.attachment_file_name = attachment.file.filename
    self.attachment_content_type = attachment.file.content_type
    self.attachment_file_size = "#{attachment.file.size} kB"
  end

  # Bloqueia remover/trocar um laudo já congelado no snapshot de alguma versão
  # publicada. Em rascunho (sem versões) o anexo é livre.
  def prevent_destroy_if_versioned
    return if iep.blank? || attachment_file_name.blank?
    return unless iep.iep_versions.where('content::text LIKE ?', "%#{attachment_file_name}%").exists?

    errors.add(:base, I18n.t('activerecord.errors.models.iep_attachment.attributes.base.referenced_by_version'))
    throw(:abort)
  end
end
