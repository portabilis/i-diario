class TeachingPlanAttachment < ActiveRecord::Base
  belongs_to :teaching_plan

  mount_uploader :attachment, DocUploader

  delegate :filename, to: :attachment
end
