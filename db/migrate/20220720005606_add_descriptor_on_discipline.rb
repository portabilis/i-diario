class AddDescriptorOnDiscipline < ActiveRecord::Migration
  def change
    add_column :disciplines, :descriptor, :boolean, default: false
    add_index :disciplines, :descriptor
  end
end
