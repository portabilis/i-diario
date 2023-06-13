class ChangeLessonPlansOldContentsTypeToNullable < ActiveRecord::Migration[4.2]
  def change
    change_column_null :lesson_plans, :old_contents, true
  end
end
