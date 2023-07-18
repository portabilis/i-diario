class ChangeEmailAndCpfOnUsers < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :email, :string, null: true, default: nil

    execute <<-SQL
      UPDATE users SET cpf = null WHERE cpf = '';
      UPDATE users u1 SET cpf = null WHERE (SELECT COUNT(*) FROM users u2 WHERE u2.cpf = u1.cpf) > 1;
    SQL

    add_index :users, :cpf, unique: true
  end
end
