class TeacherDisciplineClassroom < ActiveRecord::Base
  acts_as_copy_target

  # acts_as_paranoid

  audited

  include Audit

  belongs_to :teacher
  belongs_to :discipline
  belongs_to :classroom

  validates :teacher, :teacher_api_code, :discipline_api_code, :classroom_api_code, :year, presence: true

  default_scope { where(arel_table[:active].eq(true)) }

  scope :by_classroom, ->(classroom) { where(classroom: classroom) }
  scope :by_score_type, ->(score_type) { where(score_type: score_type) }
  scope :by_teacher_id, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :by_year, ->(year) { where(year: year) }
end
