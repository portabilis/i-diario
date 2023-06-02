class RemoveAuthorIdFromAbsenceJustifications < ActiveRecord::Migration[4.2]
  def change
    remove_column :absence_justifications, :author_id
  end
end
