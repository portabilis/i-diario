class StudentUnification
  belongs_to :student
  has_many :unified_students, through: :student_unification_students
  accepts_nested_attributes_for :unified_students
end
