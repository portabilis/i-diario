class AddPostInfoToClassrooms < ActiveRecord::Migration
  def change
    add_column :classrooms, :post_info, :boolean, default: true
  end
end
