class ComplementaryExam < ActiveRecord::Base
  include Audit
  include Stepable

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :complementary_exam_setting

  has_many :students, -> { includes(:student).ordered },
    class_name: 'ComplementaryExamStudent',
    dependent: :destroy

  accepts_nested_attributes_for :students, allow_destroy: true

  scope :by_complementary_exam_setting, lambda { |complementary_exam_setting_id| where(complementary_exam_setting_id: complementary_exam_setting_id) }
  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_grade_id, lambda { |grade_id| joins(:classroom).merge(Classroom.by_grade(grade_id)) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_student_id, lambda { |student_id| joins(:students).where(compelementary_exam_students: { student_id: student_id }) }
  scope :by_recorded_at, lambda { |recorded_at| where(recorded_at: recorded_at) }
  scope :by_date_range, lambda { |start_at, end_at| where(recorded_at: start_at..end_at) }
  scope :ordered, -> { order(recorded_at: :desc) }

  validates_date :recorded_at
  validates :unity, presence: true
  validates :classroom, presence: true
  validates :discipline, presence: true
  validates :complementary_exam_setting, presence: true

  validate :at_least_one_assigned_student

  delegate :maximum_score, to: :complementary_exam_setting
  before_validation :self_assign_to_students

  def test_date
    recorded_at
  end

  private

  def at_least_one_assigned_student
    errors.add(:students, :at_least_one_assigned_student) if students.reject(&:marked_for_destruction?).empty?
  end

  def self_assign_to_students
    students.each { |student| student.complementary_exam = self }
  end
end
