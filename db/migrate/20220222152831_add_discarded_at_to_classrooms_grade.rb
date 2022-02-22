class AddDiscardedAtToClassroomsGrade < ActiveRecord::Migration
  def change
    add_column :classrooms_grades, :discarded_at, :datetime
  end
end
