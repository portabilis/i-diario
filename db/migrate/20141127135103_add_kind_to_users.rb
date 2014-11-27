class AddKindToUsers < ActiveRecord::Migration
  def change
    add_column :users, :kind, :string, default: "employee"
  end
end
