class AbsenceJustificationAttachment < ActiveRecord::Base
  belongs_to :absence_justification

  mount_uploader :attachment, DocUploader

  validates :attachment, presence: true

  def filename
    attachment&.path&.split('/')&.last
  end
end
