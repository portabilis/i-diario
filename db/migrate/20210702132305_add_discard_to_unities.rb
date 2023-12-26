class AddDiscardToUnities < ActiveRecord::Migration[4.2]
  def change
    return if Unity.column_names.include?('discarded_at')

    add_column :unities, :discarded_at, :datetime
    add_index :unities, :discarded_at
  end
end
