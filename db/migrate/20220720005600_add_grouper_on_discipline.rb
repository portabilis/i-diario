class AddGrouperOnDiscipline < ActiveRecord::Migration
  def change
    add_column :disciplines, :grouper, :boolean, default: false
    add_index :disciplines, :grouper
  end
end
