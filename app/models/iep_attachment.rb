class IepAttachment < ApplicationRecord
  audited associated_with: :iep,
          except: [:attachment_updated_at, :attachment, :individualized_educational_plan_id]

  # touch: mantém o updated_at do plano (coluna "Última edição" do index) atualizado
  # ao anexar/remover um documento sem mexer em colunas do próprio plano.
  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id, touch: true

  mount_uploader :attachment, DocUploader

  delegate :filename, to: :attachment

  validate :attachment_extension_whitelist

  before_save :set_attachment_attributes

  private

  def attachment_extension_whitelist
    return unless attachment.present? && !attachment.file.extension.match(/\A(jpeg|jpg|png|gif|pdf|odt|doc|docx|ods|xls|xlsx|odp|ppt|pptx|odg|xml|csv)\z/i)

    errors.add(:attachment, I18n.t('activerecord.errors.models.iep_attachment.attributes.attachment.invalid_extension'))
  end

  def set_attachment_attributes
    return unless attachment.present? && attachment.file.present?

    self.attachment_file_name = attachment.file.filename
    self.attachment_content_type = attachment.file.content_type
    self.attachment_file_size = "#{(attachment.file.size / 1024.0).round} kB"
  end
end
