class AddActiveColumnOnUnities < ActiveRecord::Migration[4.2]
  def change
    add_column :unities, :active, :boolean, default: true
  end
end
