class CreateUniqueDailyFrequencyStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :unique_daily_frequency_students do |t|
      t.references :student, index: true, foreign_key: true
      t.references :classroom, index: true, foreign_key: true
      t.date :frequency_date, null: false
      t.boolean :present, null: false, default: false
      t.text :absences_by, array: true, default: []

      t.timestamps null: false
    end
  end
end
