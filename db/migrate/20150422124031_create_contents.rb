class CreateContents < ActiveRecord::Migration[4.2]
  def change
    create_table :contents do |t|
      t.references :unity, index: true, null: false
      t.references :classroom, index: true, null: false
      t.references :discipline, index: true, null: false
      t.references :school_calendar, index: true, null: false
      t.date :content_date, null: false
      t.integer :class_number, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_foreign_key :contents, :unities
    add_foreign_key :contents, :classrooms
    add_foreign_key :contents, :disciplines
    add_foreign_key :contents, :school_calendars
  end
end