class RemoveColumnDependenceFromDailyFrequencyStudents < ActiveRecord::Migration
  def change
    remove_column :daily_frequency_students, :dependence, :boolean
  end
end
