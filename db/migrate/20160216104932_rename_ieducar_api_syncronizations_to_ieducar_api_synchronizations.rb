class RenameIeducarApiSyncronizationsToIeducarApiSynchronizations < ActiveRecord::Migration[4.2]
  def change
    rename_table :ieducar_api_syncronizations, :ieducar_api_synchronizations
  end
end
