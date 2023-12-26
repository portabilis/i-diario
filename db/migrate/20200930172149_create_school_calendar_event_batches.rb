class CreateSchoolCalendarEventBatches < ActiveRecord::Migration[4.2]
  def change
    create_table :school_calendar_event_batches do |t|
      t.integer :year, null: false
      t.string :description, null: false
      t.string :periods, array: true, default: Periods.list
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :event_type, null: false
      t.string :legend, limit: 1
      t.boolean :show_in_frequency_record, default: false
      t.string :batch_status, null: false
      t.string :error_message

      t.timestamps
    end
  end
end
