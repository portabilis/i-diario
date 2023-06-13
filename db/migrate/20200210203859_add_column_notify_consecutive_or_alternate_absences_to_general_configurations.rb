class AddColumnNotifyConsecutiveOrAlternateAbsencesToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :notify_consecutive_or_alternate_absences, :boolean, default: false
  end
end
