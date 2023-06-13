class CreateSchoolCalendarEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :school_calendar_events do |t|
       t.references :school_calendar, index: true, null: false
       t.string :description, null: false
       t.date :event_date, null: false
       t.string :event_type, null: false

       t.timestamps
     end

     add_foreign_key :school_calendar_events, :school_calendars
  end
end
