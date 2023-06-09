class AddProfilePictureToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :profile_picture, :string
  end
end
