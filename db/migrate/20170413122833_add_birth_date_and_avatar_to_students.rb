class AddBirthDateAndAvatarToStudents < ActiveRecord::Migration
  def change
    add_column :students, :birth_date, :date
    add_column :students, :avatar_url, :string
  end
end
