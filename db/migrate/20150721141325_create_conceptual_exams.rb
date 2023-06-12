class CreateConceptualExams < ActiveRecord::Migration[4.2]
  def change
    create_table :conceptual_exams do |t|
      t.references :classroom, index: true, null: false, foreign_key: true
      t.references :discipline, index: true, null: false, foreign_key: true
      t.references :school_calendar_step, index: true, null: false, foreign_key: true

      t.timestamps
    end
  end
end
