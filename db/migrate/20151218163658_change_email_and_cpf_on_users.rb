class ChangeEmailAndCpfOnUsers < ActiveRecord::Migration
  def change
    change_column :users, :email, :string, null: true, default: nil

    execute <<-SQL
      UPDATE users SET cpf = null WHERE cpf = '';
    SQL

    add_index :users, :cpf, unique: true
  end
end
