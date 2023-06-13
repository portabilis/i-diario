class CreateSystemNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :system_notifications do |t|
      t.integer :source_id, null: false
      t.string :source_type, null: false
      t.string :title, null: false
      t.text :description, null: false

      t.timestamps
    end
    add_index :system_notifications, [:source_id, :source_type]
  end
end
