class AddColumnDaysToConsiderAlternateAbsencesToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :days_to_consider_alternate_absences, :integer
  end
end
