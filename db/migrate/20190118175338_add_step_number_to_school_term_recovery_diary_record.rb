class AddStepNumberToSchoolTermRecoveryDiaryRecord < ActiveRecord::Migration[4.2]
  def change
    add_column :school_term_recovery_diary_records, :step_number, :integer, null: false, default: 0
  end
end
