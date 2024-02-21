class AddFullSynchronizationToIeducarApiSynchronizations < ActiveRecord::Migration[4.2]
  def change
    add_column :ieducar_api_synchronizations, :full_synchronization, :boolean
  end
end
