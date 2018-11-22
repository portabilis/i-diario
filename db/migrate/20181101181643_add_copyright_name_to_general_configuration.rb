class AddCopyrightNameToGeneralConfiguration < ActiveRecord::Migration
  def change
    add_column :general_configurations, :copyright_name, :string
  end
end
