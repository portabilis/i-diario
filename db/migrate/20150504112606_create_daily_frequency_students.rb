class CreateDailyFrequencyStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :daily_frequency_students do |t|
      t.references :daily_frequency, index: true, null: false
      t.references :student, index: true, null: false
      t.boolean :present

      t.timestamps
    end

    add_foreign_key :daily_frequency_students, :daily_frequencies
    add_foreign_key :daily_frequency_students, :students
  end
end
