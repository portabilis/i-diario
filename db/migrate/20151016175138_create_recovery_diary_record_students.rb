class CreateRecoveryDiaryRecordStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :recovery_diary_record_students do |t|
      t.decimal :score, null: true

      t.references :recovery_diary_record, index: { name: 'index_on_recovery_diary_record_id' }, null: false
      t.references :student, index: true, null: false
    end

    add_foreign_key :recovery_diary_record_students, :recovery_diary_records
    add_foreign_key :recovery_diary_record_students, :students

    add_index(
      :recovery_diary_record_students,
      [:recovery_diary_record_id, :student_id],
      unique: true,
      name: 'index_on_recovery_diary_record_id_and_student_id'
    )
  end
end
