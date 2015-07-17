class CreateTeachingPlans < ActiveRecord::Migration
  def change
    create_table :teaching_plans do |t|
      t.integer :classroom_id, null: false
      t.integer :discipline_id, null: false
      t.integer :school_calendar_step_id, null: false
      t.string :objectives
      t.string :content
      t.string :methodology
      t.string :evaluation
      t.string :references

      t.timestamps
    end

    add_index :teaching_plans, :classroom_id
    add_index :teaching_plans, :discipline_id
    add_index :teaching_plans, :school_calendar_step_id

    add_foreign_key :teaching_plans, :classrooms
    add_foreign_key :teaching_plans, :disciplines
    add_foreign_key :teaching_plans, :school_calendar_steps
  end
end
