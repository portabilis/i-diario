class ChangeColumnOldRecordToDefaultFalse < ActiveRecord::Migration[4.2]
  def change
    change_column :conceptual_exams, :old_record, :boolean, default: false
  end
end
