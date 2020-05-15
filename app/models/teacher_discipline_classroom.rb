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

  after_create :create_teacher_profile

  after_discard do
    destroy_teacher_profiles
  end

  after_undiscard do
    create_teacher_profile
  end

  def destroy_teacher_profiles
    TeacherProfile.where(teacher_profile_arguments).destroy_all
  end

  def create_teacher_profile
    TeacherProfile.find_or_create_by!(teacher_profile_arguments)
  end

  def teacher_profile_arguments
    classroom ||= Classroom.with_discarded.find(classroom_id)

    {
      classroom_id: classroom_id,
      discipline_id: discipline_id,
      year: year,
      unity_id: classroom.unity_id,
      teacher_id: teacher_id
    }
  end
end
