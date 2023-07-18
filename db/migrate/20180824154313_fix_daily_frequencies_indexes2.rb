class FixDailyFrequenciesIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :daily_frequencies, column: [:classroom_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :daily_frequencies, column: [:discipline_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :daily_frequencies, column: [:unity_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :daily_frequencies, :classroom_id, algorithm: :concurrently
    add_index :daily_frequencies, :discipline_id, algorithm: :concurrently
    add_index :daily_frequencies, :unity_id, algorithm: :concurrently
  end
end
