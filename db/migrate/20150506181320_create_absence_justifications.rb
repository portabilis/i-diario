class CreateAbsenceJustifications < ActiveRecord::Migration[4.2]
  def change
    create_table :absence_justifications do |t|
      t.references :student, index: true, null: false
      t.date :absence_date, null: false
      t.text :justification, null: false

      t.timestamps
    end

    add_foreign_key :absence_justifications, :students
  end
end
