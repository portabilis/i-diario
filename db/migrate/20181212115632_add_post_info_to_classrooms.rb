class AddPostInfoToClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :classrooms, :post_info, :boolean, default: true
  end
end
