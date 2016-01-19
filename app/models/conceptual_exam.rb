class ConceptualExam < ActiveRecord::Base
  include Audit
  include Filterable

  acts_as_copy_target

  audited
  has_associated_audits

  attr_accessor :unity_id

  belongs_to :classroom
  belongs_to :school_calendar_step
  belongs_to :student
  has_many :conceptual_exam_values, dependent: :destroy

  accepts_nested_attributes_for :conceptual_exam_values

  has_enumeration_for :status, with: ConceptualExamStatus,  create_helpers: true

  scope :by_classroom, lambda { |classroom| where(classroom: classroom) }
  scope :by_student_name, lambda { |student_name| joins(:student).where(Student.arel_table[:name].matches("%#{student_name}%")) }
  scope :by_school_calendar_step, lambda { |school_calendar_step| where(school_calendar_step: school_calendar_step) }
  scope :ordered, -> { order(recorded_at: :desc)  }

  validates :classroom,  presence: true
  validates :school_calendar_step, presence: true
  validates :student, presence: true
  validates :recorded_at, presence: true

  before_validation :self_assign_to_conceptual_exam_values

  def self.by_status(status)
    incomplete_conceptual_exams_ids = ConceptualExamValue.where(value: nil)
      .group(:conceptual_exam_id)
      .pluck(:conceptual_exam_id)

    case status
    when ConceptualExamStatus::INCOMPLETE
      where(arel_table[:id].in(incomplete_conceptual_exams_ids))
    when ConceptualExamStatus::COMPLETE
      where.not(arel_table[:id].in(incomplete_conceptual_exams_ids))
    end
  end

  def status
    if conceptual_exam_values.any? { |conceptual_exam_value| conceptual_exam_value.value.blank? }
      ConceptualExamStatus::INCOMPLETE
    else
      ConceptualExamStatus::COMPLETE
    end
  end

  private

  def self_assign_to_conceptual_exam_values
    conceptual_exam_values.each { |conceptual_exam_value| conceptual_exam_value.conceptual_exam = self }
  end
end
