class CreateTeacherProfiles < ActiveRecord::Migration[4.2]
  def change
    create_table :teacher_profiles do |t|
      t.integer :user_id
      t.integer :teacher_id
      t.integer :role_id
      t.integer :classroom_id
      t.integer :year
      t.integer :unity_id
      t.integer :discipline_id
      t.integer :sequence

      t.timestamps null: false
    end

    add_foreign_key :teacher_profiles, :users
    add_foreign_key :teacher_profiles, :teachers
    add_foreign_key :teacher_profiles, :classrooms
    add_foreign_key :teacher_profiles, :unities
    add_foreign_key :teacher_profiles, :disciplines
    add_foreign_key :teacher_profiles, :roles
  end
end
