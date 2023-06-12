class AddColumnActiveToDailyFrequencyStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_frequency_students, :active, :boolean
  end
end
