class TeachingPlanAttachment < ActiveRecord::Base
  belongs_to :teaching_plan

  has_attached_file :attachment,
                    validate_media_type: false,
                    url: "/#{Rails.env}/:class/:id/:basename-:hash.:extension",
                    path: "/#{Rails.env}/:class/:id/:basename-:hash.:extension",
                    hash_secret: "#{Rails.application.secrets.secret_key_base}"
  validates_attachment_file_name :attachment, matches: [/png\z/, /jpeg\z/, /jpg\z/, /gif\z/, /pdf\z/, /odt\z/,
                                                        /doc\z/, /docx\z/, /ods\z/, /xls\z/, /xlsx\z/, /odp\z/,
                                                        /ppt\z/, /pptx\z/, /odg\z/, /xml\z/, /csv\z/]
  validates_with AttachmentSizeValidator, attributes: :attachment, less_than: 3.megabytes

  validates :attachment, presence: true
end
