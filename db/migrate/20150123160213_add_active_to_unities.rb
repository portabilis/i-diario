class AddActiveToUnities < ActiveRecord::Migration
  def change
    add_column :unities, :active, :boolean, default: false

    execute <<-SQL
      UPDATE unities SET active = 't'
    SQL
  end
end
