class AddIndexOnDailyFrequencyStudent < ActiveRecord::Migration[4.2]
  def change
    add_index :daily_frequency_students, :daily_frequency_id
  end
end
