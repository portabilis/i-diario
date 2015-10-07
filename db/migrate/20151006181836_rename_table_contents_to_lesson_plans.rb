class RenameTableContentsToLessonPlans < ActiveRecord::Migration
  def change
    rename_table :contents, :lesson_plans
  end
end
