class CreateDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    create_table :daily_frequencies do |t|
      t.references :unity, index: true, null: false
      t.references :classroom, index: true, null: false
      t.date :frequency_date, null: false
      t.boolean :global_absence
      t.references :discipline, index: true
      t.integer :class_number

      t.timestamps
    end

    add_foreign_key :daily_frequencies, :unities
    add_foreign_key :daily_frequencies, :classrooms
    add_foreign_key :daily_frequencies, :disciplines
  end
end
