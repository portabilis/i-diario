class ConceptualExamStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :conceptual_exam, except: :conceptual_exam_id

  belongs_to :conceptual_exam
  belongs_to :student

  validates :conceptual_exam, :student, presence: true

  def value_options
    conceptual_exam.classroom.exam_rule.rounding_table.values
  end
end