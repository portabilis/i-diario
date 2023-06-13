class AddColumnMaxConsecutiveAbsenceDaysToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :max_consecutive_absence_days, :integer
  end
end
