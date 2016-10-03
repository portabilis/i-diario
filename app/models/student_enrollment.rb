class StudentEnrollment < ActiveRecord::Base
  belongs_to :student

  has_many :student_enrollment_classrooms

  scope :by_classroom, lambda { |classroom_id| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_classroom(classroom_id)) }
  scope :by_student, lambda { |student_id| where(student_id: student_id) }
  scope :by_date, lambda { |date| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date(date)) }
  scope :by_date_not_before, lambda { |date| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date_not_before(date)) }
  scope :active, -> { where(active: 1) }
  scope :ordered, -> { joins(:student, :student_enrollment_classrooms).order('sequence ASC, students.name ASC') }
end
