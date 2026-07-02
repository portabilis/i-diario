class CreateDisciplineRecordDeletions < ActiveRecord::Migration[5.0]
  def change
    create_table :discipline_record_deletions do |t|
      t.jsonb :filters, null: false, default: {}
      t.integer :total_deleted, null: false, default: 0
      t.string :status, default: 'completed'
      t.text :error_message
      t.integer :operation_id

      t.timestamps
    end

    create_table :discipline_record_deletion_postings do |t|
      t.references :discipline_record_deletion, foreign_key: true, null: false, index: { name: 'idx_deletion_postings_on_deletion_id' }
      t.string :record_type, null: false
      t.jsonb :records_data, default: []

      t.timestamps
    end
  end
end
