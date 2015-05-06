class DailyFrequency < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :avaliation

  has_many :students, class_name: "DailyFrequencyStudent", dependent: :destroy
  accepts_nested_attributes_for :students

  validates :unity, :classroom, :frequency_date, presence: true
  validates :global_absence, inclusion: [true, false]
  validates :discipline, presence: true, unless: :global_absence?

  scope :ordered, -> { order(arel_table[:class_number].asc) }

  def build_or_find_by_student student
    students.where(student_id: student.id).first || students.build(student_id: student.id, present: 1)
  end
end