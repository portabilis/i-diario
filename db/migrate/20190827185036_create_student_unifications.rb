class CreateStudentUnifications < ActiveRecord::Migration[4.2]
  def change
    create_table :student_unifications do |t|
      t.belongs_to :student
      t.datetime :unified_at
      t.boolean :active
      t.timestamps
    end
  end
end
