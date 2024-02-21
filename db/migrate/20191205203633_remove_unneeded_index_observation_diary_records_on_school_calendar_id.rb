class RemoveUnneededIndexObservationDiaryRecordsOnSchoolCalendarId < ActiveRecord::Migration[4.2]
  def change
    remove_index :observation_diary_records, name: "index_observation_diary_records_on_school_calendar_id"
  end

  def down
    execute %{
      CREATE INDEX index_observation_diary_records_on_school_calendar_id ON public.observation_diary_records USING btree (school_calendar_id);
    }
  end
end
