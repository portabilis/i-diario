class AddShowInactiveEnrollmentToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :show_inactive_enrollments, :boolean, default: false
  end
end
