class AddTimestampsToRecoveryDiaryRecord < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:recovery_diary_record_students)
    add_timestamps(:school_term_recovery_diary_records)

  end
end
