class AddColumnActiveToDailyFrequencyStudents < ActiveRecord::Migration
  def change
    add_column :daily_frequency_students, :active, :boolean
  end
end
