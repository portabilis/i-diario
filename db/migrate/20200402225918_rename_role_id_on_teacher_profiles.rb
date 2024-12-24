class RenameRoleIdOnTeacherProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :teacher_profiles, :user_role_id, :integer
    add_foreign_key :teacher_profiles, :user_roles
    remove_column :teacher_profiles, :role_id, :integer
  end

  def down
    add_column :teacher_profiles, :role_id, :integer
    add_foreign_key :teacher_profiles, :roles
    remove_column :teacher_profiles, :user_role_id, :integer
  end
end
