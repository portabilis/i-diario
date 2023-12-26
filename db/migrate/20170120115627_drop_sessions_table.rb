class DropSessionsTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end
  end
end
