class TeachingPlanAttachment < ActiveRecord::Base
  belongs_to :teaching_plan

  mount_uploader :attachment, DocUploader

  validates :attachment, presence: true

  def filename
    attachment&.path&.split('/')&.last
  end
end
