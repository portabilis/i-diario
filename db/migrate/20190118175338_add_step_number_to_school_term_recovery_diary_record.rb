class AddStepNumberToSchoolTermRecoveryDiaryRecord < ActiveRecord::Migration
  def change
    add_column :school_term_recovery_diary_records, :step_number, :integer, null: false, default: 0
  end
end
