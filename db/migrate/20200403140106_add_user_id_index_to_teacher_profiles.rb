class AddUserIdIndexToTeacherProfiles < ActiveRecord::Migration
  def change
    add_index :teacher_profiles, :user_id
  end
end
