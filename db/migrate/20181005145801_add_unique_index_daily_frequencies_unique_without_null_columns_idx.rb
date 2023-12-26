class AddUniqueIndexDailyFrequenciesUniqueWithoutNullColumnsIdx < ActiveRecord::Migration[4.2]
  def change
    add_index :daily_frequencies, [:classroom_id, :frequency_date, :discipline_id, :class_number],
      name: 'daily_frequencies_unique_without_null_columns_idx', unique: true,
      where: 'discipline_id IS NOT NULL AND class_number IS NOT NULL'
  end
end
