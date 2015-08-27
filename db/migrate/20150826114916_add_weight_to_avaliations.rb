class AddWeightToAvaliations < ActiveRecord::Migration
  def change
    add_column :avaliations, :weight, :decimal, null: true
  end
end
