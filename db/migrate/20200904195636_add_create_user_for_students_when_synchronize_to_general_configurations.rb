class AddCreateUserForStudentsWhenSynchronizeToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :create_users_for_students_when_synchronize, :boolean, default: false
  end
end
