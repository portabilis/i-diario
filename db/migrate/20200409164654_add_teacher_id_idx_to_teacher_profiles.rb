class AddTeacherIdIdxToTeacherProfiles < ActiveRecord::Migration[4.2]
  def change
    add_index :teacher_profiles, :teacher_id
  end
end
