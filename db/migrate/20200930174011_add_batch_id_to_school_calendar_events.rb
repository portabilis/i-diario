class AddBatchIdToSchoolCalendarEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_events, :batch_id, :integer
    add_foreign_key :school_calendar_events, :school_calendar_event_batches, foreign_key: true, column: :batch_id
  end
end
