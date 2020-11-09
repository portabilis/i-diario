class ObservationDiaryRecordAttachment < ActiveRecord::Base
  audited

  belongs_to :observation_diary_record

  mount_uploader :attachment, DocUploader

  validates :attachment, presence: true

  def filename
    attachment&.path&.split('/')&.last
  end
end
