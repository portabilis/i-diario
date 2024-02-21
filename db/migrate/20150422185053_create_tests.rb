class CreateTests < ActiveRecord::Migration[4.2]
  def change
    create_table :tests do |t|
      t.references :unity, index: true, null: false
      t.references :classroom, index: true, null: false
      t.references :discipline, index: true, null: false
      t.references :test_setting, index: true, null: false
      t.references :school_calendar, index: true, null: false
      t.date :test_date, null: false
      t.integer :class_number, null: false

      t.references :test_setting_test, index: true
      t.string :description

      t.timestamps
    end

    add_foreign_key :tests, :unities
    add_foreign_key :tests, :classrooms
    add_foreign_key :tests, :disciplines
    add_foreign_key :tests, :test_settings
    add_foreign_key :tests, :school_calendars
    add_foreign_key :tests, :test_setting_tests
  end
end
