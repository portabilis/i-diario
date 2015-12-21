class ChangeEmailAndCpfOnUsers < ActiveRecord::Migration
  def change
    change_column :users, :email, :string, null: true, default: nil
    add_index :users, :cpf, unique: true
  end
end
