class CreateObjectivesTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :objectives_teaching_plans do |t|
      t.references :objective, null: false, foreign_key: true
      t.references :teaching_plan, null: false, foreign_key: true

      t.timestamps null: false
    end
  end
end
