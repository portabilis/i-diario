class AddHideNoSchoolEventsOnAttendanceRecordReportToGeneralConfigurations < ActiveRecord::Migration[5.0]
  def change
    add_column :general_configurations, :hide_no_school_events_on_attendance_record_report, :boolean, default: false
  end
end
