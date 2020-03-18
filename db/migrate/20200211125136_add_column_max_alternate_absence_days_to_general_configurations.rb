class AddColumnMaxAlternateAbsenceDaysToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :max_alternate_absence_days, :integer
  end
end
