class TeacherDisciplineClassroom < ActiveRecord::Base
  include Audit
  include Discardable

  acts_as_copy_target

  audited

  belongs_to :teacher
  belongs_to :discipline
  belongs_to :classroom

  has_many :student_enrollment_classrooms, through: :classroom

  has_enumeration_for :period, with: Periods, skip_validation: true

  validates :teacher, :teacher_api_code, :discipline_api_code, :classroom_api_code, :year, presence: true

  default_scope { where(active: true).kept }

  scope :by_classroom, ->(classroom) { where(classroom: classroom) }
  scope :by_score_type, ->(score_type) { where(score_type: score_type) }
  scope :by_teacher_id, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :by_discipline_id, ->(discipline_id) { where(discipline_id: discipline_id) }
  scope :by_grade_id, ->(grade_id) { joins(:classroom).merge(Classroom.by_grade(grade_id)) }
  scope :by_year, ->(year) { where(year: year) }
  scope :by_knowledge_area_id, ->(knowledge_area_id) {
    joins(:discipline).where(disciplines: { knowledge_area_id: knowledge_area_id })
  }

end
