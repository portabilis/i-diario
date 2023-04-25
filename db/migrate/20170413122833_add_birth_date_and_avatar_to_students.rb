class AddBirthDateAndAvatarToStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :students, :birth_date, :date
    add_column :students, :avatar_url, :string
  end
end
