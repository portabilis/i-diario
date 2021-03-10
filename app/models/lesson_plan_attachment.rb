class LessonPlanAttachment < ActiveRecord::Base
  audited

  belongs_to :lesson_plan

  mount_uploader :attachment, DocUploader

  delegate :filename, to: :attachment
end
