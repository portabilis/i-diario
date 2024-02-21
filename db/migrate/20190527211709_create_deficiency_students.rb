class CreateDeficiencyStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :deficiency_students do |t|
      t.references :deficiency, index: true, foreign_key: true
      t.references :student, index: true, foreign_key: true
      t.references :unity, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
