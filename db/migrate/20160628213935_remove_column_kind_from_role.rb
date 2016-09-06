class RemoveColumnKindFromRole < ActiveRecord::Migration
  def change
    remove_column :roles, :kind, :string
  end
end
