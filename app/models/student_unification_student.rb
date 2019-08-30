class StudentUnificationStudent < ActiveRecord::Base
  audited associated_with: :student_unification

  belongs_to :student_unification
  belongs_to :student
end
