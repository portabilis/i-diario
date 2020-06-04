class AddTeacherProfileIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :teacher_profile_id, :integer
    add_foreign_key :users, :teacher_profiles
  end
end
