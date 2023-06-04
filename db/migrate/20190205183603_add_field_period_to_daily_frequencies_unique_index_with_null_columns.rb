class AddFieldPeriodToDailyFrequenciesUniqueIndexWithNullColumns < ActiveRecord::Migration[4.2]
  def change
    remove_index :daily_frequencies, name: 'daily_frequencies_unique_with_null_columns_idx'
    add_index :daily_frequencies, [:classroom_id, :frequency_date, :period],
              name: 'daily_frequencies_unique_with_null_columns_idx', unique: true,
              where: 'discipline_id IS NULL AND class_number IS NULL'
  end
end
