class CreateLessonPlanAttachments < ActiveRecord::Migration[4.2]
  def change
    create_table :lesson_plan_attachments do |t|
      t.references :lesson_plan, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
