class CreateSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :school_term_recovery_diary_records do |t|
      t.references(
        :recovery_diary_record,
        index: { name: 'idx_school_term_recov_diary_records_on_recovery_diary_record_id' },
        null: false
      )
      t.references(
        :school_calendar_step,
        index: { name: 'idx_school_term_recove_diary_records_on_school_calendar_step_id' },
        null: false
      )
    end

    add_foreign_key :school_term_recovery_diary_records, :recovery_diary_records
    add_foreign_key :school_term_recovery_diary_records, :school_calendar_steps

    add_index(
      :school_term_recovery_diary_records,
      [:recovery_diary_record_id, :school_calendar_step_id],
      unique: true,
      name: 'index_on_recovery_diary_record_id_and_school_calendar_step_id'
    )
  end
end
