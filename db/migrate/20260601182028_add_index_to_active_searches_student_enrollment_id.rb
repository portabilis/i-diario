class AddIndexToActiveSearchesStudentEnrollmentId < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    add_index :active_searches,
              :student_enrollment_id,
              where: 'discarded_at IS NULL',
              name: :index_active_searches_on_student_enrollment_id_not_discarded,
              algorithm: :concurrently
  end

  def down
    remove_index :active_searches,
                 name: :index_active_searches_on_student_enrollment_id_not_discarded,
                 algorithm: :concurrently
  end
end
