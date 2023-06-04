class AddCopyrightNameToGeneralConfiguration < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :copyright_name, :string
  end
end
