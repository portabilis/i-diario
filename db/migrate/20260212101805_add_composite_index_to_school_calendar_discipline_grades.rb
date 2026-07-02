class AddCompositeIndexToSchoolCalendarDisciplineGrades < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    execute <<-SQL
      DELETE FROM school_calendar_discipline_grades
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM school_calendar_discipline_grades
        GROUP BY school_calendar_id, discipline_id, grade_id
      )
    SQL

    add_index :school_calendar_discipline_grades,
              [:school_calendar_id, :grade_id, :discipline_id],
              name: 'idx_scdg_on_school_calendar_discipline_grade',
              unique: true,
              algorithm: :concurrently
  end

  def down
    remove_index :school_calendar_discipline_grades,
                 name: 'idx_scdg_on_school_calendar_discipline_grade',
                 algorithm: :concurrently
  end
end
