class AddIndexOnDailyFrequencyStudent < ActiveRecord::Migration
  def change
    add_index :daily_frequency_students, :daily_frequency_id
  end
end
