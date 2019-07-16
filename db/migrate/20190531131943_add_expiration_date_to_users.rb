class AddExpirationDateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :expiration_date, :date
  end
end
