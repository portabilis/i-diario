class CreateObservationDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :observation_diary_records do |t|
      t.references :school_calendar, null: false, index: true, foreign_key: true
      t.references :teacher, null: false, index: true, foreign_key: true
      t.references :classroom, null: false, index: true, foreign_key: true
      t.references :discipline, index: true, foreign_key: true

      t.date :date, null: false

      t.timestamps null: false
    end

    add_index(
      :observation_diary_records,
      [:school_calendar_id, :teacher_id, :classroom_id, :discipline_id, :date],
      unique: true,
      name: :idx_obs_diary_on_school_calen_teacher_classroom_discip_and_date
    )
  end
end
