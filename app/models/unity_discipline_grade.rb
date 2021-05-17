class UnityDisciplineGrade < ActiveRecord::Base
  belongs_to :unity
  belongs_to :discipline
  belongs_to :grade
end
