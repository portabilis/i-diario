class AddDiscardedAtToDailyFrequencyStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_frequency_students, :discarded_at, :datetime
  end
end
