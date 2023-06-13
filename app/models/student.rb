class Student < ApplicationRecord
  include Discardable

  acts_as_copy_target

  audited

  has_one :user

  has_and_belongs_to_many :users

  has_many :student_enrollments
  has_many :absence_justifications_students
  has_many :absence_justifications, through: :absence_justifications_students
  has_many :avaliation_exemptions
  has_many :complementary_exam_students
  has_many :conceptual_exams
  has_many :daily_frequency_students
  has_many :daily_note_students
  has_many :descriptive_exam_students
  has_many :observation_diary_record_note_students
  has_many :recovery_diary_record_students
  has_many :transfer_notes
  has_many :deficiency_students, dependent: :destroy
  has_many :deficiencies, through: :deficiency_students
  has_many :student_unifications
  has_many :student_unification_students

  attr_accessor :exempted_from_discipline, :in_active_search

  validates :name, presence: true
  validates :api_code, presence: true, if: :api?

  after_save :update_name_tokens

  default_scope -> { kept }

  scope :api, -> { where(arel_table[:api].eq(true)) }
  scope :ordered, -> { order(:name) }
  scope :by_name, lambda { |name|
    where(
      "students.name_tokens @@ plainto_tsquery('portuguese', ?)", name
    ).order(
      "ts_rank_cd(students.name_tokens, plainto_tsquery('portuguese', '#{name}')) desc"
    )
  }

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
    return I18n.t('.student.display_name_format', social_name: social_name, name: name) if social_name.present?

    name
  end

  def display_name
    @display_name ||= social_name || name
  end

  def first_name
    display_name.blank? ? '' : display_name.split(' ')[0]
  end

  def average(classroom, discipline, step)
    StudentAverageCalculator.new(self).calculate(classroom, discipline, step)
  end

  def classrooms
    Classroom.joins(classrooms_grades: :student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_student(self.id)).distinct
  end

  def current_classrooms
    Classroom.joins(classrooms_grades: :student_enrollment_classrooms).merge(
      StudentEnrollmentClassroom.by_student(id)
                                .by_date(Date.current)
    ).distinct
  end

  private

  def update_name_tokens
    Student.where(id: id).update_all("name_tokens = to_tsvector('portuguese', name)")
  end
end
