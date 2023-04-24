class AddApicodeToStudentUnification < ActiveRecord::Migration
  def change
    add_column :student_unifications, :api_code, :integer
  end
end
