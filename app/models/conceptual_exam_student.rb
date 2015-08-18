class ConceptualExamStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :conceptual_exam, except: :conceptual_exam_id

  belongs_to :conceptual_exam
  belongs_to :student

  validates :conceptual_exam, :student, presence: true

  scope :by_classroom_discipline_and_step,
        lambda { |classroom_id, discipline_id, step_id| where(
                                                       'conceptual_exams.classroom_id' => classroom_id,
                                                       'conceptual_exams.discipline_id' => discipline_id,
                                                       'conceptual_exams.school_calendar_step_id' => step_id)
                                                          .includes(:conceptual_exam) }

  def value_options
    conceptual_exam.classroom.exam_rule.rounding_table.values
  end
end