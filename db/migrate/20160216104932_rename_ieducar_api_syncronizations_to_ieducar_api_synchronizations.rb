class RenameIeducarApiSyncronizationsToIeducarApiSynchronizations < ActiveRecord::Migration
  def change
    rename_table :ieducar_api_syncronizations, :ieducar_api_synchronizations
  end
end
