class RenameTableContentsToLessonPlans < ActiveRecord::Migration[4.2]
  def change
    rename_table :contents, :lesson_plans
  end
end
