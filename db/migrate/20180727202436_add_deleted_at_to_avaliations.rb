class AddDeletedAtToAvaliations < ActiveRecord::Migration[4.2]
  def change
    add_column :avaliations, :deleted_at, :datetime
    add_index :avaliations, :deleted_at
  end
end
