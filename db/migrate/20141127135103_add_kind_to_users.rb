class AddKindToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :kind, :string, default: "employee"
  end
end
