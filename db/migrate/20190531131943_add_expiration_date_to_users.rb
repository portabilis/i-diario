class AddExpirationDateToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :expiration_date, :date
  end
end
