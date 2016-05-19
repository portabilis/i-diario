class AddTeacherIdToTransferNote < ActiveRecord::Migration
  def change
    remove_column :transfer_notes, :user_id
    add_column :transfer_notes, :teacher_id, :integer, index: true
    add_foreign_key :transfer_notes, :teachers
  end
end
