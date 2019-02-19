class AddSocialNameToStudent < ActiveRecord::Migration
  def change
    add_column :students, :social_name, :string
  end
end
