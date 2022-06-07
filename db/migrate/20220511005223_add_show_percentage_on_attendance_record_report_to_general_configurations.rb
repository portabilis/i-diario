class AddShowPercentageOnAttendanceRecordReportToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :show_percentage_on_attendance_record_report, :boolean, default: false
  end
end
