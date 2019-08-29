class StudentUnificationStudent < ActiveRecord::Base
  include Audit

  audited associated_with: :student_unification

  belongs_to :student_unification
  belongs_to :student
end
