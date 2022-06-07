class CreateLabels < ActiveRecord::Migration
  def change
    create_table :labels do |t|
      t.string :name
      t.string :labelable_type
      t.integer :labelable_id

      t.timestamps null: false
    end

    add_index :labels, [:labelable_type, :labelable_id]
  end
end
