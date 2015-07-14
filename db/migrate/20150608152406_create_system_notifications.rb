class CreateSystemNotifications < ActiveRecord::Migration
  def change
    create_table :system_***REMOVED*** do |t|
      t.integer :source_id, null: false
      t.string :source_type, null: false
      t.string :title, null: false
      t.text :description, null: false

      t.timestamps
    end
    add_index :system_***REMOVED***, [:source_id, :source_type]
  end
end
