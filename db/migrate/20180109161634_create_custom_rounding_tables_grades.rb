class CreateCustomRoundingTablesGrades < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_rounding_tables_grades, id: false do |t|
      t.belongs_to :custom_rounding_table
      t.belongs_to :grade
    end

    add_index :custom_rounding_tables_grades, :custom_rounding_table_id,
      name: 'idx_custom_rounding_tables_grades_on_custom_rounding_table_id'
    add_index :custom_rounding_tables_grades, :grade_id,
      name: 'idx_custom_rounding_tables_grades_on_grade_id'
  end
end
