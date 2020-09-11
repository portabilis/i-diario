class RemoveColumnUnityIdFromDeficiencyStudents < ActiveRecord::Migration
  def change
    remove_column :deficiency_students, :unity_id
  end
end
