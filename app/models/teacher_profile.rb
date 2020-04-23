class TeacherProfile < ActiveRecord::Base
  belongs_to :teacher, touch: true
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :unity

  has_many :users, dependent: :nullify

  def self.generate(teacher)
    transaction do
      teacher
        .teacher_discipline_classrooms
        .includes(:classroom, :discipline, teacher: { users: { user_roles: :role } })
        .find_each(&:create_teacher_profile)
    end
  end
end
