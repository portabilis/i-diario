class AddColumnMaxConsecutiveAbsenceDaysToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :max_consecutive_absence_days, :integer
  end
end
