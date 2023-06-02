class CreateDailyNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :daily_notes do |t|
      t.references :unity, index: true, null: false
      t.references :classroom, index: true, null: false
      t.references :discipline, index: true, null: false
      t.references :avaliation, index: true, null: false

      t.timestamps
    end

    add_foreign_key :daily_notes, :unities
    add_foreign_key :daily_notes, :classrooms
    add_foreign_key :daily_notes, :disciplines
    add_foreign_key :daily_notes, :avaliations
  end
end
