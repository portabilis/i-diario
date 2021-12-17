class CopyDisciplineTeachingPlanForm
  include ActiveModel::Model

  attr_accessor :unities_ids,
                :grades_ids,
                :year,
                :discipline_teaching_plan,
                :teaching_plan

  validates :unities_ids,
            :grades_ids,
            :year,
            :discipline_teaching_plan,
            :teaching_plan,
            presence: true
end
