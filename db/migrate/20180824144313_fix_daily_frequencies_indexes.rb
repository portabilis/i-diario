class FixDailyFrequenciesIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :daily_frequencies, :classroom_id
    remove_index :daily_frequencies, :discipline_id
    remove_index :daily_frequencies, :unity_id

    add_index :daily_frequencies, :classroom_id, where: "deleted_at IS NULL"
    add_index :daily_frequencies, :discipline_id, where: "deleted_at IS NULL"
    add_index :daily_frequencies, :unity_id, where: "deleted_at IS NULL"
  end
end
