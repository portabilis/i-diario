class AddDeletedAtToAvaliations < ActiveRecord::Migration
  def change
    add_column :avaliations, :deleted_at, :datetime
    add_index :avaliations, :deleted_at
  end
end
