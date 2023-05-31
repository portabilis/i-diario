class AddApicodeToStudentUnification < ActiveRecord::Migration[4.2]
  def change
    add_column :student_unifications, :api_code, :integer
  end
end
