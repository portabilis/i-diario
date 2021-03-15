class AddCanPostToClassrooms < ActiveRecord::Migration
  def change
    add_column :classrooms, :can_post, :boolean, default: true
  end
end
