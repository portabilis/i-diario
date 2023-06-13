class CreateCustomRoundingTablesCourses < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_rounding_tables_courses do |t|
      t.belongs_to :custom_rounding_table
      t.belongs_to :course
    end

    add_index :custom_rounding_tables_courses, :custom_rounding_table_id,
      name: 'idx_custom_rounding_tables_courses_on_custom_rounding_table_id'
    add_index :custom_rounding_tables_courses, :course_id,
      name: 'idx_custom_rounding_tables_courses_on_course_id'
  end
end
