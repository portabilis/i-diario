class AbsenceJustificationAttachment < ActiveRecord::Base
  belongs_to :absence_justification

  mount_uploader :attachment, DocUploader

  delegate :filename, to: :attachment
end
