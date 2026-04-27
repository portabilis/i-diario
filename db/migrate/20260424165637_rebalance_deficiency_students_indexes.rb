class RebalanceDeficiencyStudentsIndexes < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_deficiency_students_on_student_deficiency_unity'.freeze

  def up
    add_index :deficiency_students,
              [:student_id, :deficiency_id, :unity_id],
              name: INDEX_NAME,
              algorithm: :concurrently

    remove_index :deficiency_students, column: :student_id, algorithm: :concurrently
  end

  def down
    add_index :deficiency_students, :student_id, algorithm: :concurrently

    remove_index :deficiency_students, name: INDEX_NAME, algorithm: :concurrently
  end
end
