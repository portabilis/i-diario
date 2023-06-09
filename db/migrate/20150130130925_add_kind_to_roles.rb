class AddKindToRoles < ActiveRecord::Migration[4.2]
  def change
    add_column :roles, :kind, :string
  end
end
