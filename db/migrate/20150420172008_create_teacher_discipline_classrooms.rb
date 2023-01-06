class CreateTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def change
    create_table :teacher_discipline_classrooms do |t|
      t.references :teacher, index: true, null: false
      t.references :discipline, index: true
      t.references :classroom, index: true
      t.string :teacher_api_code, null: false
      t.string :discipline_api_code, null: false
      t.string :classroom_api_code, null: false
      t.integer :year, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_foreign_key :teacher_discipline_classrooms, :teachers
    add_foreign_key :teacher_discipline_classrooms, :disciplines
    add_foreign_key :teacher_discipline_classrooms, :classrooms
  end
end
