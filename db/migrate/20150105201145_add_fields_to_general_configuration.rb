class AddFieldsToGeneralConfiguration < ActiveRecord::Migration
  def change
  	add_column :general_configurations, :employees_default_role_id, :integer, references: :roles
  end
end
