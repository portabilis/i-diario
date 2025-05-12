class AddDiscardedAtToClassroomsGrade < ActiveRecord::Migration[4.2]
  def change
    add_column :classrooms_grades, :discarded_at, :datetime
  end
end
