class AddSocialNameToStudent < ActiveRecord::Migration[4.2]
  def change
    add_column :students, :social_name, :string
  end
end
