class CreateIepOptions < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_options do |t|
      t.integer :kind, null: false               # grupo do multi-select (8 kinds)
      t.string :description, null: false
      t.integer :position
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :iep_options, :kind
  end
end
