class CreateComplementaryExams < ActiveRecord::Migration[4.2]
  def change
    create_table :complementary_exams do |t|
      t.date :recorded_at, null: false

      t.references :unity, index: true, null: false
      t.references :classroom, index: true, null: false
      t.references :discipline, index: true, null: false
      t.references :complementary_exam_setting, index: true, null: false
    end

    add_foreign_key :complementary_exams, :unities
    add_foreign_key :complementary_exams, :classrooms
    add_foreign_key :complementary_exams, :disciplines
  end
end
