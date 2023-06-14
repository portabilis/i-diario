class AddShowSchoolTermRecoveryInExamRecordReportToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :show_school_term_recovery_in_exam_record_report, :boolean, default: false
  end
end
