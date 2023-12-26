class CreateUserLogins < ActiveRecord::Migration[4.2]
  def change
    create_table :user_logins do |t|
      t.integer :user_id, null: false
      t.string :sign_in_ip, null: false

      t.timestamps
    end
    add_index :user_logins, :user_id
    add_foreign_key :user_logins, :users
  end
end
