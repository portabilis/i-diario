class AddColumnDaysToConsiderAlternateAbsencesToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :days_to_consider_alternate_absences, :integer
  end
end
