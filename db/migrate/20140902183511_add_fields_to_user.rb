class AddFieldsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :login, :string
    add_column :users, :phone, :string
    add_column :users, :cpf, :string
    add_column :users, :authorize_email_and_sms, :boolean, default: false
  end
end
