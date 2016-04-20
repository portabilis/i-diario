class RemoveAuthorIdFromAbsenceJustifications < ActiveRecord::Migration
  def change
    remove_column :absence_justifications, :author_id
  end
end
