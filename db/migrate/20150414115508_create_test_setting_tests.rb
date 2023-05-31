class CreateTestSettingTests < ActiveRecord::Migration[4.2]
  def change
    create_table :test_setting_tests do |t|
      t.references :test_setting, index: true, null: false
      t.string :description, null: false
      t.decimal :weight, null: false
      t.string :test_type, null: false

      t.timestamps
    end

    add_foreign_key :test_setting_tests, :test_settings
  end
end
