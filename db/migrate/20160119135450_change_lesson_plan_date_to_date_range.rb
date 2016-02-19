class ChangeLessonPlanDateToDateRange < ActiveRecord::Migration
  def change
    rename_column :lesson_plans, :lesson_plan_date, :start_at
    add_column :lesson_plans, :end_at, :date

    execute <<-SQL
      UPDATE lesson_plans SET end_at = start_at;
    SQL

    change_column_null :lesson_plans, :end_at, false

  end
end
