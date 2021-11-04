class AddTypeOfTeachingToDailyFrequencyStudents < ActiveRecord::Migration
  def change
    add_column :daily_frequency_students, :type_of_teaching, :integer, default: 1
  end
end
