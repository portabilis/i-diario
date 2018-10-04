class AddUniqueIndexToIeducarApiSynchronizations < ActiveRecord::Migration
  def change
    add_index :ieducar_api_synchronizations, [:ieducar_api_configuration_id, :status],
      name: 'ieducar_api_synchronizations_unique_index', unique: true, where: "status = 'started'"
  end
end
