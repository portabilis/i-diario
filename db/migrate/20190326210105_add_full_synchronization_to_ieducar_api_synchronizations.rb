class AddFullSynchronizationToIeducarApiSynchronizations < ActiveRecord::Migration
  def change
    add_column :ieducar_api_synchronizations, :full_synchronization, :boolean
  end
end
