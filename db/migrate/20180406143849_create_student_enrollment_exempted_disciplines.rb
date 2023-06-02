class CreateStudentEnrollmentExemptedDisciplines < ActiveRecord::Migration[4.2]
  def change
    create_table :student_enrollment_exempted_disciplines do |t|
      t.references :student_enrollment
      t.references :discipline
      t.string :steps

      t.timestamps null: false
    end

    add_foreign_key :student_enrollment_exempted_disciplines, :student_enrollments,
      column: :student_enrollment_id, name: 'fk_exempted_disciplines_student_enrollment_id'

    add_foreign_key :student_enrollment_exempted_disciplines, :disciplines,
      column: :discipline_id, name: 'fk_exempted_disciplines_discipline_id'

    add_index :student_enrollment_exempted_disciplines, :student_enrollment_id,
      name: 'idx_exempted_disciplines_student_enrollment_id'

    add_index :student_enrollment_exempted_disciplines, :discipline_id,
      name: 'idx_exempted_disciplines_discipline_id'
  end
end
