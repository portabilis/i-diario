class StudentUnificationStudent < ActiveRecord::Base
  include Audit

  audited

  belongs_to :student_unification
  belongs_to :student
end
