class FixDailyFrequenciesIndexes < ActiveRecord::Migration
  def change
    remove_index :daily_frequencies, name: :daily_frequencies_unique_idx if index_exists?(:daily_frequencies, name: :daily_frequencies_unique_idx)
    remove_index :daily_frequencies, :classroom_id
    remove_index :daily_frequencies, :discipline_id
    remove_index :daily_frequencies, :unity_id

    add_index :daily_frequencies, [:unity_id, :classroom_id, :frequency_date, :discipline_id, :class_number, :school_calendar_id], where: "deleted_at IS NULL", name: :daily_frequencies_unique_idx, unique: true
    add_index :daily_frequencies, :classroom_id, where: "deleted_at IS NULL"
    add_index :daily_frequencies, :discipline_id, where: "deleted_at IS NULL"
    add_index :daily_frequencies, :unity_id, where: "deleted_at IS NULL"
  end
end
