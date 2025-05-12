class CreateAvaliationRecoveryLowestNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :avaliation_recovery_lowest_notes do |t|
      t.references :recovery_diary_record, index: { name: 'idx_recovery_diary_record_id_on_recovery_lowest_note' },
                   null: false, foreign_key: true
      t.date :recorded_at, null: false
      t.integer :step_number, null: false
      t.timestamps null: false
    end
  end
end
