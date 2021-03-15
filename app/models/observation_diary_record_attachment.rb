class ObservationDiaryRecordAttachment < ActiveRecord::Base
  audited

  belongs_to :observation_diary_record

  mount_uploader :attachment, DocUploader

  delegate :filename, to: :attachment
end
