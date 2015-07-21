class DescriptiveExamStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :descriptive_exam, except: :descriptive_exam_id

  belongs_to :descriptive_exam
  belongs_to :student

  validates :descriptive_exam, :student, presence: true
end