class CreateWorkerStates < ActiveRecord::Migration[4.2]
  def change
    create_table :worker_states do |t|
      t.references :user, index: true, foreign_key: true
      t.string :job_id
      t.string :kind
      t.string :status
      t.string :error_message

      t.timestamps null: false
    end
  end
end
