class AddObservationsToAvaliations < ActiveRecord::Migration
  def change
    add_column :avaliations, :observations, :text
  end
end
