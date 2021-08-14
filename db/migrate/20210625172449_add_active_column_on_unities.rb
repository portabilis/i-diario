class AddActiveColumnOnUnities < ActiveRecord::Migration
  def change
    add_column :unities, :active, :boolean, default: true
  end
end
