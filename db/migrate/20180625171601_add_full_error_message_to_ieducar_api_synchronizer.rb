class AddFullErrorMessageToIeducarApiSynchronizer < ActiveRecord::Migration
  def change
    add_column :ieducar_api_synchronizations, :full_error_message, :string
  end
end
