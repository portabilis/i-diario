class DropDailyFrequenciesUniqueIdx < ActiveRecord::Migration
  def change
    remove_index :daily_frequencies, name: 'daily_frequencies_unique_idx'
  end
end
