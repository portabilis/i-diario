class ConceptualExamValue < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :conceptual_exam, except: :conceptual_exam_id

  belongs_to :conceptual_exam
  belongs_to :discipline

  validates :conceptual_exam, presence: true
  validates :discipline, presence: true
end
