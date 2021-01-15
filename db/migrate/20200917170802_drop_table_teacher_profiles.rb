class DropTableTeacherProfiles < ActiveRecord::Migration
  def change
    remove_column :users, :teacher_profile_id
    drop_table :teacher_profiles
  end
end
