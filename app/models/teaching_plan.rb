class TeachingPlan < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit
  include Filterable

  has_enumeration_for :school_term_type, with: SchoolTermTypes, create_helpers: true
  has_enumeration_for :school_term, with: Bimesters

  belongs_to :classroom
  belongs_to :discipline

  has_many :teacher_discipline_classrooms, -> { where(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(TeachingPlan.arel_table[:discipline_id])) }, through: :classroom

  validates :year,       presence: true
  validates :unity_id,   presence: true
  validates :classroom,  presence: true
  validates :discipline, presence: true
  validates :school_term_type, presence: true
  validates :school_term, presence: { unless: :yearly?  }

  scope :by_teacher_classroom_and_discipline, lambda { |teacher_id, classroom_id, discipline_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id, discipline_id: discipline_id}) }
  scope :by_teacher, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }
  scope :by_year, lambda { |year| where(year: year) }
  scope :by_unity_id, lambda { |unity_id| joins(:classroom).where(classrooms: { unity_id: unity_id }) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_school_term_type, lambda { |school_term_type| where(school_term_type: school_term_type) }
  scope :by_school_term, lambda { |school_term| where(school_term: school_term) }

  def unity_id
    classroom.unity_id if classroom
  end
end
