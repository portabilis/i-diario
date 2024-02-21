class CreateWorkerBatches < ActiveRecord::Migration[4.2]
  def change
    create_table :worker_batches do |t|
      t.string :main_job_class, null: false
      t.string :main_job_id, null: false
      t.integer :total_workers, default: 0
      t.integer :done_workers, default: 0
      t.text :completed_workers, array: true, default: []

      t.timestamps null: false
    end
  end
end
