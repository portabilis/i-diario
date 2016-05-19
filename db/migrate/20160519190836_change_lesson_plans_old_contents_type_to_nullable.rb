class ChangeLessonPlansOldContentsTypeToNullable < ActiveRecord::Migration
  def change
    change_column_null :lesson_plans, :old_contents, true
  end
end
