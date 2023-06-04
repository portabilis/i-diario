class CreateTransferNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :transfer_notes do |t|
      t.integer :classroom_id, index: true, null: false
      t.integer :discipline_id, index: true, null: false
      t.integer :school_calendar_step_id, index: true, null: false
      t.date :transfer_date, null: false
      t.integer :student_id, null: false, index: true

      t.timestamps
    end
    add_foreign_key :transfer_notes, :classrooms
    add_foreign_key :transfer_notes, :disciplines
    add_foreign_key :transfer_notes, :school_calendar_steps
    add_foreign_key :transfer_notes, :students
  end
end
