class DeleteInactiveSteps < ActiveRecord::Migration
  def change
    execute <<-SQL
      DELETE
        FROM school_calendar_steps
       WHERE NOT active;

      DELETE
        FROM school_calendar_classroom_steps
       WHERE NOT active;
    SQL
  end
end
