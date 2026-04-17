class AddFunctionalIndexesToUsersCpfAndLogin < ActiveRecord::Migration[5.0]

  disable_ddl_transaction!
  def change

    add_index :users, 'lower(cpf)',
              unique: true,
              algorithm: :concurrently,
              name: 'index_users_on_lower_cpf'

    add_index :users, 'lower(login)',
              algorithm: :concurrently,
              name: 'index_users_on_lower_login'
  end
end