class StudentEnrollment < ActiveRecord::Base
  belongs_to :student

  has_many :student_enrollment_classrooms
  has_many :dependences, class_name: "StudentEnrollmentDependence"

  scope :by_classroom, lambda { |classroom_id| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_classroom(classroom_id)) }
  scope :by_discipline, lambda {|discipline_id| by_discipline_query(discipline_id)}
  scope :by_student, lambda { |student_id| where(student_id: student_id) }
  scope :by_date, lambda { |date| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date(date)) }
  scope :by_date_not_before, lambda { |date| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date_not_before(date)) }
  scope :show_as_inactive, lambda { joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.show_as_inactive) }
  scope :active, -> { where(active: 1) }
  scope :ordered, -> { joins(:student, :student_enrollment_classrooms).order('sequence ASC, students.name ASC') }

  def self.by_discipline_query(discipline_id)
    joins("LEFT JOIN student_enrollment_dependences on(student_enrollment_dependences.student_enrollment_id = student_enrollments.id)")
    .where("(student_enrollment_dependences.discipline_id = ? OR student_enrollment_dependences.discipline_id is null)", discipline_id)
  end
end
