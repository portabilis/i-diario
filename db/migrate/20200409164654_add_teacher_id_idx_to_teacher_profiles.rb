class AddTeacherIdIdxToTeacherProfiles < ActiveRecord::Migration
  def change
    add_index :teacher_profiles, :teacher_id
  end
end
