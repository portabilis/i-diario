class AddDiscardedAtToDailyFrequencyStudents < ActiveRecord::Migration
  def change
    add_column :daily_frequency_students, :discarded_at, :datetime
  end
end
