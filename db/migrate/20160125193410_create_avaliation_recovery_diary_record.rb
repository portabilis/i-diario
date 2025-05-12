class CreateAvaliationRecoveryDiaryRecord < ActiveRecord::Migration[4.2]
  def change
    create_table :avaliation_recovery_diary_records do |t|
      t.references :recovery_diary_record, foreign_key: true
      t.references :avaliation, foreign_key: true
    end

    add_index(
      :avaliation_recovery_diary_records,
      :recovery_diary_record_id,
      unique: true,
      name: :index_avaliation_recovery_diary_records_on_recovery_diary_id
    )

    add_index(
      :avaliation_recovery_diary_records,
      :avaliation_id,
      unique: true
    )

  end
end
