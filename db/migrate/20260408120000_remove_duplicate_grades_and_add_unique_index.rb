class RemoveDuplicateGradesAndAddUniqueIndex < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    execute <<-SQL
      DELETE FROM grades
      WHERE id IN (
        SELECT g.id
        FROM grades g
        WHERE EXISTS (
          SELECT 1 FROM grades g2
          WHERE g2.api_code = g.api_code
          AND g2.id < g.id
        )
        AND NOT EXISTS (SELECT 1 FROM classrooms_grades WHERE grade_id = g.id)
        AND NOT EXISTS (SELECT 1 FROM avaliations_grades WHERE grade_id = g.id)
        AND NOT EXISTS (SELECT 1 FROM school_calendar_discipline_grades WHERE grade_id = g.id)
        AND NOT EXISTS (SELECT 1 FROM complementary_exam_settings_grades WHERE grade_id = g.id)
        AND NOT EXISTS (SELECT 1 FROM custom_rounding_tables_grades WHERE grade_id = g.id)
        AND NOT EXISTS (SELECT 1 FROM school_calendar_events WHERE grade_id = g.id)
        AND NOT EXISTS (SELECT 1 FROM teacher_discipline_classrooms WHERE grade_id = g.id)
        AND NOT EXISTS (SELECT 1 FROM teaching_plans WHERE grade_id = g.id)
      )
    SQL

    remove_index :grades, :api_code if index_exists?(:grades, :api_code)

    add_index :grades, :api_code,
              unique: true,
              algorithm: :concurrently
  end

  def down
    remove_index :grades, :api_code if index_exists?(:grades, :api_code)

    add_index :grades, :api_code,
              algorithm: :concurrently
  end
end
