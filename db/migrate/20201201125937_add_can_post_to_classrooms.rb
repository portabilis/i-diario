class AddCanPostToClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :classrooms, :can_post, :boolean, default: true
  end
end
