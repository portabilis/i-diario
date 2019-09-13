class AddUserIdToAbsenceJustifications < ActiveRecord::Migration
  def change
    add_column :absence_justifications, :user_id, :integer
  end
end
