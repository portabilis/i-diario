class CreateSchoolCalendars < ActiveRecord::Migration[4.2]
  def change
    create_table :school_calendars do |t|
      t.integer :year, null: false
      t.integer :number_of_classes, null: false

      t.timestamps
    end
  end
end
