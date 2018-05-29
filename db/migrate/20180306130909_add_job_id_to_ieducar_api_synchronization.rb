class AddJobIdToIeducarApiSynchronization < ActiveRecord::Migration
  def change
    add_column :ieducar_api_synchronizations, :job_id, :string
  end
end
