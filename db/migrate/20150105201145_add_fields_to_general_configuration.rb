class AddFieldsToGeneralConfiguration < ActiveRecord::Migration[4.2]
  def change
  	add_column :general_configurations, :employees_default_role_id, :integer, references: :roles
  end
end
