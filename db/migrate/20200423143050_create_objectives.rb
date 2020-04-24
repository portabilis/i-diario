class CreateObjectives < ActiveRecord::Migration
  def change
    create_table :objectives do |t|
      t.string :description, null: false, index: true

      t.timestamps null: false
    end
  end
end
