class CreateRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :recovery_diary_records do |t|
      t.date :recorded_at, null: false

      t.references :unity, index: true, null: false
      t.references :classroom, index: true, null: false
      t.references :discipline, index: true, null: false
    end

    add_foreign_key :recovery_diary_records, :unities
    add_foreign_key :recovery_diary_records, :classrooms
    add_foreign_key :recovery_diary_records, :disciplines

    add_index(
      :recovery_diary_records,
      [:unity_id, :classroom_id, :discipline_id, :recorded_at],
      unique: true,
      name: 'idx_unity_id_and_classroom_id_and_discipline_id_and_recorded_at'
    )
  end
end
