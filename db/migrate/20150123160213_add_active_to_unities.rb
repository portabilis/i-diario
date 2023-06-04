class AddActiveToUnities < ActiveRecord::Migration[4.2]
  def change
    add_column :unities, :active, :boolean, default: false

    execute <<-SQL
      UPDATE unities SET active = 't'
    SQL
  end
end
