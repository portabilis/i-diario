class RemoveUnneededIndexRolePermissionsOnRoleId < ActiveRecord::Migration[4.2]
  def change
    remove_index :role_permissions, name: "index_role_permissions_on_role_id"
  end

  def down
    execute %{
      CREATE INDEX index_role_permissions_on_role_id ON public.role_permissions USING btree (role_id);
    }
  end
end
