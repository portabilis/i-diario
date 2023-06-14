class RemoveDuplicatedObjectivesTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    objectives_teaching_plans = ObjectivesTeachingPlan.group(
      :teaching_plan_id, :objective_id
    ).having(
      'COUNT(1) > 1'
    ).pluck(
      'MAX(id)', :teaching_plan_id, :objective_id
    )

    objectives_teaching_plans.each do |correct_id, teaching_plan_id, objective_id|
      ObjectivesTeachingPlan.where(
        teaching_plan_id: teaching_plan_id,
        objective_id: objective_id
      ).where.not(id: correct_id).each(&:destroy)
    end
  end
end
