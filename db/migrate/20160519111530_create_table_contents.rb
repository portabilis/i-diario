class CreateTableContents < ActiveRecord::Migration[4.2]
  def change
    create_table :contents do |t|
      t.string :description, null: false

      t.timestamps
    end
  end
end
