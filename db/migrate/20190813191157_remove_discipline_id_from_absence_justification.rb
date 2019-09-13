class RemoveDisciplineIdFromAbsenceJustification < ActiveRecord::Migration
  def change
    remove_column :absence_justifications, :discipline_id, :integer
  end
end
