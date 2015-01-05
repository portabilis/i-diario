class AddFieldsToGeneralConfiguration < ActiveRecord::Migration
  def change
  	add_column :general_configurations, :students_default_role_id, :integer, references: :roles
  	add_column :general_configurations, :employees_default_role_id, :integer, references: :roles
  	add_column :general_configurations, :parents_default_role_id, :integer, references: :roles
  end
end
