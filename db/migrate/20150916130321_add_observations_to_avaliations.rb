class AddObservationsToAvaliations < ActiveRecord::Migration[4.2]
  def change
    add_column :avaliations, :observations, :text
  end
end
