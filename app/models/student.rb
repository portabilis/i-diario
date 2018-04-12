class Student < ActiveRecord::Base
  acts_as_copy_target

  has_one :user

  has_and_belongs_to_many :users

  has_many :***REMOVED***, dependent: :restrict_with_error
  has_many :student_biometrics
  has_many :student_enrollments

  attr_accessor :exempted_from_discipline

  validates :name, presence: true
  validates :api_code, presence: true, if: :api?

  scope :api, -> { where(arel_table[:api].eq(true)) }
  scope :ordered, -> { order(:name) }

  def self.search(value)
    relation = all

    if value.present?
      relation = relation.where(%Q(
        name ILIKE :text OR api_code = :code
      ), text: "%#{value}%", code: value)
    end

    relation
  end

  def to_s
    name
  end

  def first_name
    name.blank? ? "" : name.split(" ")[0]
  end

  def average(classroom, discipline, step)
    StudentAverageCalculator.new(self)
      .calculate(classroom, discipline, step)
  end

  def classrooms
    Classroom.joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_student(self.id)).uniq
  end
end
