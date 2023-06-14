class AddColumnOldRecordToConceptualExams < ActiveRecord::Migration[4.2]
  def change
    add_column :conceptual_exams, :old_record, :boolean, default: true
  end
end
