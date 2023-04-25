class RemoveDisciplineIdFromAbsenceJustification < ActiveRecord::Migration[4.2]
  def change
    remove_column :absence_justifications, :discipline_id, :integer
  end
end
