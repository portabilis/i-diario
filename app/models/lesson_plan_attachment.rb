class LessonPlanAttachment < ActiveRecord::Base
  audited

  belongs_to :lesson_plan

  mount_uploader :attachment, DocUploader

  validates :attachment, presence: true

  def filename
    attachment&.path&.split('/')&.last
  end
end
