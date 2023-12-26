class RemoveColumnKindFromRole < ActiveRecord::Migration[4.2]
  def change
    remove_column :roles, :kind, :string
  end
end
