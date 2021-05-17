class RemoveClassroomIdFromAvaliations < ActiveRecord::Migration
  def change
    remove_column :avaliations, :classroom_id
  end
end
