class ConceptualExam < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits
  before_save :mark_students_for_removal

  include Audit

  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar_step

  delegate :unity, to: :classroom, allow_nil: true

  has_many :students, class_name: 'ConceptualExamStudent', dependent: :destroy
  accepts_nested_attributes_for :students

  validates :classroom,  presence: true
  validates :discipline, presence: true
  validates :school_calendar_step, presence: true

  def mark_students_for_removal
    students.each do |student|
      student.mark_for_destruction if student.value.blank?
    end
  end
end