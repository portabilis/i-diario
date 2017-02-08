class DropIndexDeficienciesOnName < ActiveRecord::Migration
  def change
    remove_index :deficiencies, "name"
  end
end
