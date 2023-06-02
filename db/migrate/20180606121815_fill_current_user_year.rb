class FillCurrentUserYear < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
    UPDATE users
      SET current_school_year =
      CASE WHEN current_classroom_id IS NULL THEN
      extract(year from NOW())
      ELSE
      (SELECT "year"
      FROM classrooms
      WHERE classrooms.id = current_classroom_id
      )
      END;
    SQL
  end
end
