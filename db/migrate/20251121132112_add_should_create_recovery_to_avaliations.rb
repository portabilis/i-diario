class AddShouldCreateRecoveryToAvaliations < ActiveRecord::Migration[5.0]
  def change
    add_column :avaliations, :should_create_recovery, :boolean, default: false
  end
end
