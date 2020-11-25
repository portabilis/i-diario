class TeacherUnification < ActiveRecord::Base
  audited

  belongs_to :teacher
  has_many :unified_teachers, class_name: 'TeacherUnificationTeacher', dependent: :restrict_with_error
end
