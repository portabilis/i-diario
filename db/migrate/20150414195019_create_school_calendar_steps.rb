class CreateSchoolCalendarSteps < ActiveRecord::Migration[4.2]
  def change
    create_table :school_calendar_steps do |t|
      t.references :school_calendar, index: true, null: false
      t.date :start_at, null: false
      t.date :end_at, null: false

      t.timestamps
    end

    add_foreign_key :school_calendar_steps, :school_calendars
  end
end
