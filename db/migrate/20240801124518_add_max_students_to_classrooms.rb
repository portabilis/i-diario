class AddMaxStudentsToClassrooms < ActiveRecord::Migration[5.0]
  def change
    add_column :classrooms, :max_students, :integer
  end
end
