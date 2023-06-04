class RemoveDuplicatedContentsTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    contents_teaching_plans = ContentsTeachingPlan.group(
      :teaching_plan_id, :content_id
    ).having(
      'COUNT(1) > 1'
    ).pluck(
      'MAX(id)', :teaching_plan_id, :content_id
    )

    contents_teaching_plans.each do |correct_id, teaching_plan_id, content_id|
      ContentsTeachingPlan.where(
        teaching_plan_id: teaching_plan_id,
        content_id: content_id
      ).where.not(id: correct_id).each(&:destroy)
    end
  end
end
