class CreateObjectives < ActiveRecord::Migration[4.2]
  def change
    create_table :objectives do |t|
      t.text :description, null: false

      t.timestamps null: false
    end
  end
end
