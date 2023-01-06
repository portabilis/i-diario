class CreateFinalRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :final_recovery_diary_records do |t|
      t.references(
        :recovery_diary_record,
        index: true,
        null: false
      )
      t.references(
        :school_calendar,
        index: true,
        null: false
      )
    end

    add_foreign_key :final_recovery_diary_records, :recovery_diary_records
    add_foreign_key :final_recovery_diary_records, :school_calendars

    add_index(
      :final_recovery_diary_records,
      [:recovery_diary_record_id, :school_calendar_id],
      unique: true,
      name: 'index_on_recovery_diary_record_id_and_school_calendar_id'
    )
  end
end
