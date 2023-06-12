class GroupedDiscipline < ApplicationRecord
  scope :by_teacher_unity_and_year, lambda { |teacher_id, unity_id, year|
    where(teacher_id: teacher_id, unity_id: unity_id, year: year)
  }
end
