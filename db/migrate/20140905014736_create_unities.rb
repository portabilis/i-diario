class CreateUnities < ActiveRecord::Migration[4.2]
  def change
    create_table :unities do |t|
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :responsible
      t.string :api_code
      t.integer :author_id, null: false
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :unities, :name, unique: true
    add_index :unities, :author_id
    add_index :unities, :discarded_at
    add_foreign_key :unities, :users, column: :author_id
  end
end
