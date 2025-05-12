class AddGrouperOnDiscipline < ActiveRecord::Migration[4.2]
  def change
    add_column :disciplines, :grouper, :boolean, default: false
    add_index :disciplines, :grouper
  end
end
