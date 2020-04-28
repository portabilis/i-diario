class CreateObjectives < ActiveRecord::Migration
  def change
    create_table :objectives do |t|
      t.text :description, null: false, index: true

      t.timestamps null: false
    end
  end
end
