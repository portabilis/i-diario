class TeacherUnificationTeacher < ActiveRecord::Base
  audited associated_with: :teacher_unification

  belongs_to :teacher_unification
  belongs_to :teacher
end
