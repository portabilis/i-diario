class DropIndexDeficienciesOnName < ActiveRecord::Migration[4.2]
  def change
    remove_index :deficiencies, "name"
  end
end
