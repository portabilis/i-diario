class AddWeightToAvaliations < ActiveRecord::Migration[4.2]
  def change
    add_column :avaliations, :weight, :decimal, null: true
  end
end
