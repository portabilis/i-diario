class CreateContentsTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :contents_teaching_plans do |t|
      t.integer :content_id, null: false, index: true
      t.integer :teaching_plan_id, null: false, index: true
    end
    add_foreign_key :contents_teaching_plans, :contents
    add_foreign_key :contents_teaching_plans, :teaching_plans
  end
end
