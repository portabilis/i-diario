class StudentUnification < ApplicationRecord
  audited

  belongs_to :student
  has_many :unified_students, class_name: 'StudentUnificationStudent', dependent: :restrict_with_error
end
