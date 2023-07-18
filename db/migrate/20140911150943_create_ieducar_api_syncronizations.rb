class CreateIeducarApiSyncronizations < ActiveRecord::Migration[4.2]
  def change
    create_table :ieducar_api_syncronizations do |t|
      t.integer :ieducar_api_configuration_id
      t.string :status
      t.integer :author_id
      t.text :error_message
      t.boolean :notified, default: false

      t.timestamps
    end
    add_index :ieducar_api_syncronizations, :ieducar_api_configuration_id,
      name: "api_config_idx_on_ias"
    add_index :ieducar_api_syncronizations, :author_id
    add_foreign_key :ieducar_api_syncronizations, :ieducar_api_configurations
    add_foreign_key :ieducar_api_syncronizations, :users, column: :author_id
  end
end
