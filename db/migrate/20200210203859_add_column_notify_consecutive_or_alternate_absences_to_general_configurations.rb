class AddColumnNotifyConsecutiveOrAlternateAbsencesToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :notify_consecutive_or_alternate_absences, :boolean, default: false
  end
end
