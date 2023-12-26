class AddTypeOfTeachingToDailyFrequencyStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_frequency_students, :type_of_teaching, :integer, default: 1
  end
end
