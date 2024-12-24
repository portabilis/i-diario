class RemoveUserColumnsFromTeacherProfiles < ActiveRecord::Migration[4.2]
  def up
    remove_column :teacher_profiles, :user_id
    remove_column :teacher_profiles, :user_role_id
  end

  def down
    add_column :teacher_profiles, :user_id, :integer
    add_column :teacher_profiles, :user_role_id, :integer
    add_foreign_key :teacher_profiles, :users
    add_foreign_key :teacher_profiles, :user_roles
    add_index :teacher_profiles, :user_id
  end
end
