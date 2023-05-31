class CreateTranslations < ActiveRecord::Migration[4.2]
  def change
    create_table :translations do |t|
      t.string :key, unique: true, null: false
      t.string :label, null: false
      t.string :translation
      t.string :group, null: false
      t.string :subgroup, null: false
      t.string :hint
      t.integer :order, null: false

      t.timestamps
    end
  end
end
