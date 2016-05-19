class CreateTableContents < ActiveRecord::Migration
  def change
    create_table :contents do |t|
      t.string :description, null: false

      t.timestamps
    end
  end
end
