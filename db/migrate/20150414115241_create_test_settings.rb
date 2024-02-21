class CreateTestSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :test_settings do |t|
      t.integer :year, null: false
      t.boolean :fix_tests, null: false

      t.timestamps
    end
  end
end
