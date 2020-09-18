class Classroom < ActiveRecord::Base
  include Discardable

  LABEL_COLORS = YAML.safe_load(
    File.open(Rails.root.join('config', 'label_colors.yml'))
  ).with_indifferent_access[:label_colors].freeze

  acts_as_copy_target

  audited

  has_enumeration_for :period, with: Periods

  belongs_to :unity
  belongs_to :exam_rule
  belongs_to :grade
  has_many :teacher_discipline_classrooms, dependent: :destroy
  has_many :disciplines, through: :teacher_discipline_classrooms
  has_one :calendar, class_name: 'SchoolCalendarClassroom'
  has_many :users, foreign_key: :current_classroom_id, dependent: :nullify
  has_many :student_enrollment_classrooms
  has_many :student_enrollments, through: :student_enrollment_classrooms
  has_many :conceptual_exams, dependent: :restrict_with_error
  has_many :infrequency_trackings, dependent: :restrict_with_error
  has_many :students, through: :student_enrollments
  has_many :classroom_labels, dependent: :destroy
  has_many :labels, through: :classroom_labels

  before_create :set_label_color

  delegate :course_id, :course, to: :grade, prefix: false

  validates :description, :api_code, :unity_code, :year, :grade, presence: true
  validates :api_code, uniqueness: true

  default_scope -> { kept }

  scope :by_unity_and_teacher, lambda { |unity_id, teacher_id|
    joins(:teacher_discipline_classrooms)
      .where(unity_id: unity_id, teacher_discipline_classrooms: { teacher_id: teacher_id })
      .uniq
  }

  scope :by_unity, ->(unity) { where(unity: unity) }
  scope :by_unity_and_grade, ->(unity_id, grade_id) { where(unity_id: unity_id, grade_id: grade_id).uniq }
  scope :different_than, ->(classroom_id) { where(arel_table[:id].not_eq(classroom_id)) }
  scope :by_grade, ->(grade_id) { where(grade_id: grade_id) }
  scope :by_year, ->(year) { where(year: year) }
  scope :by_period, ->(period) { where(period: period) }

  scope :by_teacher_id, lambda { |teacher_id|
    joins(:teacher_discipline_classrooms)
      .where(teacher_discipline_classrooms: { teacher_id: teacher_id })
      .uniq
  }

  scope :by_score_type, ->(score_type) { where('exam_rules.score_type' => score_type).includes(:exam_rule) }
  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :by_api_code, ->(api_code) { where(api_code: api_code) }

  scope :by_teacher_discipline, lambda { |discipline_id|
    joins(:teacher_discipline_classrooms)
      .where(teacher_discipline_classrooms: { discipline_id: discipline_id })
      .uniq
  }

  scope :by_api_code, ->(api_code) { where(api_code: api_code) }
  scope :by_id, ->(id) { where(id: id) }
  scope :with_grade, -> { where.not(grade: nil) }

  after_discard do
    teacher_discipline_classrooms.discard_all
  end

  after_undiscard do
    teacher_discipline_classrooms.undiscard_all
  end

  def to_s
    description
  end

  def period_humanized
    Periods.t(period)
  end

  def has_differentiated_students?
    student_enrollment_classrooms.joins(student_enrollment: :student )
                                 .where(students: { uses_differentiated_exam_rule: true } )
                                 .exists?
  end

  private

  def set_label_color
    self.label_color = LABEL_COLORS.sample
  end
end
