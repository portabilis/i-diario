class AddDescriptorOnDiscipline < ActiveRecord::Migration[4.2]
  def change
    add_column :disciplines, :descriptor, :boolean, default: false
    add_index :disciplines, :descriptor
  end
end
