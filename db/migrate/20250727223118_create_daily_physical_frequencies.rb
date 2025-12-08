class CreateDailyPhysicalFrequencies < ActiveRecord::Migration[5.0]
  def change
    create_table :daily_physical_frequencies do |t|
      t.references :student_enrollment, foreign_key: true
      t.references :unity, foreign_key: true
      t.date :frequency_date
      t.boolean :present

      t.timestamps
    end
  end
end
